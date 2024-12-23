//
//  File.swift
//
//
//  Created by Gifton Okoronkwo on 11/3/24.
//

import Foundation
/// Manages the in-memory cache and persistence of the metadata network with improved
/// concurrent access, sophisticated storage handling, and advanced graph operations.
/// Manages the in-memory cache and persistence of the metadata network with improved
/// concurrent access, sophisticated storage handling, and advanced graph operations.
actor MetaDataGraph {
    // MARK: - Types
    
    enum TransactionState {
        case none
        case active(Transaction)
        case committed
        case rolledBack
    }
    
    struct Transaction {
        let id: UUID
        var operations: [Operation]
        var timestamp: Date
        
        enum Operation {
            case addNode(MetadataNode)
            case updateNode(MetadataNode)
            case deleteNode(UUID)
            case addConnection(MetadataConnection)
            case updateConnection(MetadataConnection)
            case deleteConnection(UUID)
        }
    }

    // MARK: - Properties
    
    private var nodeCache: [UUID: CacheEntry<MetadataNode>]
    private var connectionCache: [UUID: CacheEntry<MetadataConnection>]
    private let storage: MetaDataStorage
    private let cacheSize: Int
    private var currentTransaction: TransactionState = .none
    
    // Queue for managing read/write operations
    private let operationQueue: OperationQueue
    private let readQueue: DispatchQueue
    private let writeQueue: DispatchQueue
    
    // Tracking and metrics
    private var metrics: GraphMetrics
    private var lastMaintenanceDate: Date
    
    // MARK: - Initialization
    
    init(storage: MetaDataStorage, cacheSize: Int = 10000) {
        self.storage = storage
        self.cacheSize = cacheSize
        self.nodeCache = [:]
        self.connectionCache = [:]
        
        // Initialize queues
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = 4
        self.readQueue = DispatchQueue(label: "com.thoughtkit.metagraph.read", attributes: .concurrent)
        self.writeQueue = DispatchQueue(label: "com.thoughtkit.metagraph.write")
        
        self.metrics = GraphMetrics()
        self.lastMaintenanceDate = Date()
        
        // Initialize cache
        Task {
            await initializeCache()
        }
    }
    
    // MARK: - Cache Management
    
    private struct CacheEntry<T> {
        let value: T
        let lastAccessed: Date
        let accessCount: Int
        
        func updated() -> CacheEntry<T> {
            CacheEntry(value: value, lastAccessed: Date(), accessCount: accessCount + 1)
        }
    }
    
    private func initializeCache() async {
        do {
            let recentNodes = try await storage.loadAllNodes()
                .values
                .sorted { $0.lastUsed > $1.lastUsed }
                .prefix(cacheSize)
            
            for node in recentNodes {
                nodeCache[node.id] = CacheEntry(value: node, lastAccessed: Date(), accessCount: 0)
            }
            
            // Load essential connections
            let connections = try await storage.loadAllConnections()
            for connection in connections.values where connection.weight > 0.7 {
                connectionCache[connection.id] = CacheEntry(value: connection, lastAccessed: Date(), accessCount: 0)
            }
        } catch {
            metrics.recordError(.cacheInitializationFailed)
        }
    }
    
    // MARK: - Transaction Management
    
    func beginTransaction() throws -> UUID {
        guard case .none = currentTransaction else {
            throw GraphError.invalidOperation("Transaction already in progress")
        }
        
        let transaction = Transaction(id: UUID(), operations: [], timestamp: Date())
        currentTransaction = .active(transaction)
        return transaction.id
    }
    
    // MARK: - Node Operations
    func getNode(by id: UUID) async throws -> MetadataNode? {
        do {
            // Check cache with timeout
            return try await withTimeout(seconds: 2) { [self] in
                if let cached = self.nodeCache[id] {
                    let updatedEntry = cached.updated()
                    self.nodeCache[id] = updatedEntry
                    return updatedEntry.value
                }
                
                // Load from storage
                guard let node = try await storage.getNode(by: id) else {
                    return nil
                }
                
                updateNodeCache(node)
                return node
            }
        } catch let error as GraphError {
            metrics.recordError(.nodeRetrievalFailed)
            throw error
        } catch {
            metrics.recordError(.nodeRetrievalFailed)
            throw GraphError.storageError(error)
        }
    }

    func findNode(withValue value: String, type: NodeType) async -> MetadataNode? {
        // Check cache first
        if let cachedNode = nodeCache.values.first(where: {
            $0.value.type == type && $0.value.value.lowercased() == value.lowercased()
        }) {
            return cachedNode.value
        }
        
        // Load from storage
        let nodes = try? await storage.loadAllNodes()
        let foundNode = nodes?.values.first {
            $0.type == type && $0.value.lowercased() == value.lowercased()
        }
        
        if let node = foundNode {
            updateNodeCache(node)
        }
        
        return foundNode
    }

    func addNode(_ value: String, type: NodeType, metadata: [String: Double]? = nil) async throws -> UUID {
        do {
            metrics.recordOperation(.nodeAddition)
            
            // Validate input
            guard !value.isEmpty else {
                throw GraphError.invalidNodeData("Node value cannot be empty")
            }
            
            // Check resource limits
            if nodeCache.count >= cacheSize {
                throw GraphError.resourceExhausted("Node cache limit reached (\(cacheSize) nodes)")
            }
            
            // Check for existing node with timeout
            let existingNode = try await withTimeout(seconds: 5) {
                await self.findNode(withValue: value, type: type)
            }
            
            if let existingNode = existingNode {
                var updatedNode = existingNode
                updatedNode.frequency += 1
                updatedNode.lastUsed = Date()
                
                if case .active(var transaction) = currentTransaction {
                    // Validate transaction state
                    guard transaction.operations.count < 1000 else {
                        throw GraphError.resourceExhausted("Transaction operation limit exceeded")
                    }
                    
                    transaction.operations.append(.updateNode(updatedNode))
                    currentTransaction = .active(transaction)
                } else {
                    try await Task {
                        updateNodeCache(updatedNode)
                        try await storage.save(node: updatedNode)
                    }.value
                }
                
                return existingNode.id
            }
            
            // Create new node
            let node = MetadataNode(type: type, value: value)
            
            if case .active(var transaction) = currentTransaction {
                // Validate transaction size
                guard transaction.operations.count < 1000 else {
                    throw GraphError.resourceExhausted("Transaction operation limit exceeded")
                }
                
                transaction.operations.append(.addNode(node))
                currentTransaction = .active(transaction)
            } else {
                try await Task {
                    updateNodeCache(node)
                    try await storage.save(node: node)
                }.value
            }
            
            metrics.recordOperation(.nodeAddition)
            return node.id
            
        } catch let error as GraphError {
            metrics.recordError(.nodeAdditionFailed)
            throw error
        } catch {
            metrics.recordError(.nodeAdditionFailed)
            throw GraphError.invalidOperation("Failed to add node: \(error.localizedDescription)")
        }
    }
    
    func commitTransaction() async throws {
        do {
            guard case .active(let transaction) = currentTransaction else {
                throw GraphError.invalidOperation("No active transaction to commit")
            }
            
            // Validate transaction state
            guard !transaction.operations.isEmpty else {
                throw GraphError.invalidOperation("Cannot commit empty transaction")
            }
            
            // Check for operation limits
            guard transaction.operations.count <= 1000 else {
                throw GraphError.resourceExhausted("Transaction exceeds maximum operation limit")
            }
            
            // Check transaction age
            let transactionAge = Date().timeIntervalSince(transaction.timestamp)
            guard transactionAge <= 300 else { // 5 minutes
                throw GraphError.transactionFailed("Transaction expired after \(Int(transactionAge)) seconds")
            }
            
            try await Task {
                // Validate all operations before executing
                try await validateOperations(transaction.operations)
                
                // Execute operations
                for operation in transaction.operations {
                    try await executeOperation(operation)
                }
                
                // Create backup
                try await storage.createBackup()
                
                currentTransaction = .committed
            }.value
            
        } catch let error as GraphError {
            await rollbackTransaction()
            metrics.recordError(.transactionFailed)
            throw error
        } catch {
            await rollbackTransaction()
            metrics.recordError(.transactionFailed)
            throw GraphError.transactionFailed("Transaction failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Functions
    
    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw GraphError.operationTimeout
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private func validateOperations(_ operations: [Transaction.Operation]) async throws {
        for operation in operations {
            switch operation {
            case .addNode(let node):
                guard node.value.count <= 1000 else {
                    throw GraphError.validationError("Node value exceeds maximum length")
                }
            case .updateNode(let node):
                guard try await getNode(by: node.id) != nil else {
                    throw GraphError.nodeMissing(node.id)
                }
            case .deleteNode(let nodeId):
                guard try await getNode(by: nodeId) != nil else {
                    throw GraphError.nodeMissing(nodeId)
                }
            // Add validation for other operation types
            default:
                break
            }
        }
    }
    
    func updateNode(_ node: MetadataNode) async throws {
        if case .active(var transaction) = currentTransaction {
            transaction.operations.append(.updateNode(node))
            currentTransaction = .active(transaction)
        } else {
            try await Task {
                updateNodeCache(node)
                try await storage.save(node: node)
            }.value
        }
    }

    func findConnections(
        from sourceId: UUID,
        relationshipTypes: Set<MetadataRelationType>? = nil,
        minWeight: Float = 0.0
    ) async throws -> [MetadataConnection] {
        let connections = try await storage.getConnectionsOptimized(for: sourceId)
        return connections.filter { connection in
            connection.sourceId == sourceId &&
            connection.weight >= minWeight &&
            (relationshipTypes == nil || relationshipTypes!.contains(connection.type))
        }
    }
    
    // MARK: - Graph Traversal
    
    func traverseDepthFirst(
        from startId: UUID,
        maxDepth: Int = Int.max,
        condition: ((MetadataNode) -> Bool)? = nil
    ) async throws -> [MetadataNode] {
        var visited = Set<UUID>()
        var result = [MetadataNode]()
        
        func visit(_ nodeId: UUID, depth: Int) async throws {
            guard depth < maxDepth,
                  !visited.contains(nodeId),
                  let node = try await getNode(by: nodeId)
            else { return }
            
            visited.insert(nodeId)
            
            if condition?(node) ?? true {
                result.append(node)
            }
            
            let connections = try await findConnections(from: nodeId)
            for connection in connections {
                try await visit(connection.targetId, depth: depth + 1)
            }
        }
        
        try await visit(startId, depth: 0)
        return result
    }
    
    func findShortestPath(from startId: UUID, to endId: UUID) async throws -> [MetadataNode]? {
        var visited = Set<UUID>()
        var queue = [(nodeId: startId, path: [MetadataNode]())]
        
        while !queue.isEmpty {
            let (currentId, path) = queue.removeFirst()
            guard !visited.contains(currentId) else { continue }
            
            visited.insert(currentId)
            guard let currentNode = try await getNode(by: currentId) else { continue }
            
            let newPath = path + [currentNode]
            
            if currentId == endId {
                return newPath
            }
            
            let connections = try await findConnections(from: currentId)
            for connection in connections where !visited.contains(connection.targetId) {
                queue.append((connection.targetId, newPath))
            }
        }
        
        return nil
    }
    
    // MARK: - Subgraph Operations
    
    func extractSubgraph(around nodeId: UUID, radius: Int) async throws -> Set<MetadataNode> {
        var subgraph = Set<MetadataNode>()
        var visited = Set<UUID>()
        var queue = [(id: nodeId, distance: 0)]
        
        while !queue.isEmpty {
            let (currentId, distance) = queue.removeFirst()
            guard !visited.contains(currentId), distance <= radius else { continue }
            
            visited.insert(currentId)
            if let node = try await getNode(by: currentId) {
                subgraph.insert(node)
                
                let connections = try await findConnections(from: currentId)
                for connection in connections {
                    queue.append((connection.targetId, distance + 1))
                }
            }
        }
        
        return subgraph
    }
}


private extension MetaDataGraph {
    func performMaintenance() async throws {
        // Perform periodic maintenance tasks
        let now = Date()
        guard now.timeIntervalSince(lastMaintenanceDate) > 86400 else { return } // Daily maintenance
        
        // Clean up stale cache entries
        let staleThreshold = now.addingTimeInterval(-3600 * 24) // 24 hours
        nodeCache = nodeCache.filter { $0.value.lastAccessed > staleThreshold }
        connectionCache = connectionCache.filter { $0.value.lastAccessed > staleThreshold }
        
        // Optimize storage
        try await storage.cleanupStaleNodes(olderThan: 30) // 30 days
        
        lastMaintenanceDate = now
    }
    
    func executeOperation(_ operation: Transaction.Operation) async throws {
        switch operation {
        case .addNode(let node):
            updateNodeCache(node)
            try await storage.save(node: node)
            
        case .updateNode(let node):
            updateNodeCache(node)
            try await storage.save(node: node)
            
        case .deleteNode(let nodeId):
            nodeCache.removeValue(forKey: nodeId)
            // Implementation for node deletion in storage
            
        case .addConnection(let connection):
            updateConnectionCache(connection)
            try await storage.save(connection: connection)
            
        case .updateConnection(let connection):
            updateConnectionCache(connection)
            try await storage.save(connection: connection)
            
        case .deleteConnection(let connectionId):
            connectionCache.removeValue(forKey: connectionId)
            // Implementation for connection deletion in storage
        }
    }

    func rollbackTransaction() async {
        guard case .active(let transaction) = currentTransaction else { return }
        
        // Revert all operations in reverse order
        for operation in transaction.operations.reversed() {
            switch operation {
            case .addNode(let node):
                nodeCache.removeValue(forKey: node.id)
            case .updateNode(let node):
                // Restore previous version if available
                if let previous = try? await storage.getNode(by: node.id) {
                    nodeCache[node.id] = CacheEntry(value: previous, lastAccessed: Date(), accessCount: 0)
                }
            // Handle other cases similarly
            default:
                break
            }
        }
        
        currentTransaction = .rolledBack
    }
    
    func updateNodeCache(_ node: MetadataNode) {
        // Maintain cache size limit
        if nodeCache.count >= cacheSize {
            let oldestNode = nodeCache.min(by: { $0.value.lastAccessed < $1.value.lastAccessed })
            if let oldest = oldestNode {
                nodeCache.removeValue(forKey: oldest.key)
            }
        }
        nodeCache[node.id] = CacheEntry(value: node, lastAccessed: Date(), accessCount: 0)
    }
    
    func updateConnectionCache(_ connection: MetadataConnection) {
        // Maintain cache size limit
        if connectionCache.count >= cacheSize {
            let oldestConnection = connectionCache.min(by: { $0.value.lastAccessed < $1.value.lastAccessed })
            if let oldest = oldestConnection {
                connectionCache.removeValue(forKey: oldest.key)
            }
        }
        connectionCache[connection.id] = CacheEntry(value: connection, lastAccessed: Date(), accessCount: 0)
    }
}

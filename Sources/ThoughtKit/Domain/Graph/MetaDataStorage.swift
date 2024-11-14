import Foundation

/// Manages the persistence of the metadata network to and from disk.
/// Handles atomic saves and maintains data integrity through file coordination.
actor MetaDataStorage {
    // MARK: - Properties
    private let fileManager: FileManager
    private let batchSize: Int
    private let storageURL: URL
    private let thoughtsURL: URL
    private let nodesURL: URL
    private let connectionsURL: URL
    
    // MARK: - Error Handling
    enum StorageError: Error {
        case fileCreationFailed
        case dataCorrupted
        case encodingFailed
        case decodingFailed
        case invalidStorageDirectory
        case invalidBatchId
    }
    
    // MARK: - Initialization
    
    init(batchSize: Int = 1000) throws {
        self.fileManager = FileManager.default
        self.batchSize = batchSize
        
        // Set up storage directory structure
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw StorageError.invalidStorageDirectory
        }
        
        self.storageURL = documentsPath.appendingPathComponent("MetadataNetwork", isDirectory: true)
        self.thoughtsURL = storageURL.appendingPathComponent("Thoughts", isDirectory: true)
        self.nodesURL = storageURL.appendingPathComponent("Nodes", isDirectory: true)
        self.connectionsURL = storageURL.appendingPathComponent("Connections", isDirectory: true)
        
        // Create directory structure
        Task {
            try await createDirectoryStructure()
        }
    }
    
    private func createDirectoryStructure() throws {
        let directories = [storageURL, thoughtsURL, nodesURL, connectionsURL]
        for directory in directories {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
    
}

// MARK: - Node Operations
extension MetaDataStorage {
    
    /// Gets a node batch URL for a given node ID
    private func getBatchURL(for nodeId: UUID) -> URL {
        let batchId = abs(nodeId.hashValue % batchSize)
        return nodesURL.appendingPathComponent("batch_\(batchId).json")
    }
    
    /// Loads nodes from a specific batch
    private func loadNodeBatch(at url: URL) async throws -> [MetadataNode] {
        if fileManager.fileExists(atPath: url.path) {
            let data = try await loadFile(at: url)
            return try JSONDecoder().decode([MetadataNode].self, from: data)
        }
        return []
    }
    
    /// Saves nodes to a specific batch
    private func saveNodeBatch(_ nodes: [MetadataNode], to url: URL) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(nodes)
        try await saveFile(data: data, to: url)
    }
    
    /// Saves a single node
    func save(node: MetadataNode) async throws {
        let batchURL = getBatchURL(for: node.id)
        var batchNodes = try await loadNodeBatch(at: batchURL)
        
        if let index = batchNodes.firstIndex(where: { $0.id == node.id }) {
            batchNodes[index] = node
        } else {
            batchNodes.append(node)
        }
        
        try await saveNodeBatch(batchNodes, to: batchURL)
    }
    
    /// Retrieves a node by its ID
    func getNode(by id: UUID) async throws -> MetadataNode? {
        let batchURL = getBatchURL(for: id)
        let nodes = try await loadNodeBatch(at: batchURL)
        return nodes.first { $0.id == id }
    }
    
    /// Loads all nodes across all batches
    func loadAllNodes() async throws -> [UUID: MetadataNode] {
        var allNodes: [UUID: MetadataNode] = [:]
        
        // Get all batch files
        let batchFiles = try fileManager.contentsOfDirectory(
            at: nodesURL,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }
        
        // Load each batch
        try await batchFiles.asyncForEach { url in
            let nodes = try await self.loadNodeBatch(at: url)
            for node in nodes {
                allNodes[node.id] = node
            }
        }
        
        return allNodes
    }
}

// MARK: - Connection Operations
extension MetaDataStorage {
    
    private func getConnectionBatchURL(for connectionId: UUID) -> URL {
        let batchId = abs(connectionId.hashValue % batchSize)
        return connectionsURL.appendingPathComponent("batch_\(batchId).json")
    }
    
    private func loadConnectionBatch(at url: URL) async throws -> [MetadataConnection] {
        if fileManager.fileExists(atPath: url.path) {
            let data = try await loadFile(at: url)
            return try JSONDecoder().decode([MetadataConnection].self, from: data)
        }
        return []
    }
    
    func loadAllConnections() async throws -> [UUID: MetadataConnection] {
        var allConnections: [UUID: MetadataConnection] = [:]
        
        let batchFiles = try fileManager.contentsOfDirectory(
            at: connectionsURL,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }
        
        try await batchFiles.asyncForEach { url in
            let connections = try await self.loadConnectionBatch(at: url)
            for connection in connections {
                allConnections[connection.id] = connection
            }
        }
        
        return allConnections
    }
    
}

// MARK: - Thought Operations
extension MetaDataStorage {
    
    func save(thought: Thought) async throws {
        let thoughtURL = thoughtsURL.appendingPathComponent("\(thought.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(thought)
        try await saveFile(data: data, to: thoughtURL)
    }
    
    func getThought(by id: UUID) async throws -> Thought? {
        let thoughtURL = thoughtsURL.appendingPathComponent("\(id.uuidString).json")
        
        guard fileManager.fileExists(atPath: thoughtURL.path) else {
            return nil
        }
        
        let data = try await loadFile(at: thoughtURL)
        return try JSONDecoder().decode(Thought.self, from: data)
    }
    
    func loadAllThoughts() async throws -> [Thought] {
        let thoughtFiles = try fileManager.contentsOfDirectory(
            at: thoughtsURL,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }
        
        return try await thoughtFiles.asyncMap { url in
            let data = try await self.loadFile(at: url)
            return try JSONDecoder().decode(Thought.self, from: data)
        }
    }
}

// MARK: - File Operations
extension MetaDataStorage {
    
    private func loadFile(at url: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: nil) { url in
                do {
                    let data = try Data(contentsOf: url)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func saveFile(data: Data, to url: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NSFileCoordinator().coordinate(writingItemAt: url, options: [], error: nil) { url in
                do {
                    try data.write(to: url, options: .atomic)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
}

// MARK: - Maintenance Operations
extension MetaDataStorage {
    
    /// Creates a backup of the current network state
    func createBackup() async throws {
        let backupURL = storageURL.deletingLastPathComponent()
            .appendingPathComponent("MetadataNetwork_Backup_\(Date().ISO8601Format())")
        
        try fileManager.createDirectory(at: backupURL, withIntermediateDirectories: true)
        
        try fileManager.copyItem(at: thoughtsURL, to: backupURL.appendingPathComponent("Thoughts"))
        try fileManager.copyItem(at: nodesURL, to: backupURL.appendingPathComponent("Nodes"))
        try fileManager.copyItem(at: connectionsURL, to: backupURL.appendingPathComponent("Connections"))
    }
    
    /// Removes nodes that haven't been accessed in the specified number of days
    func cleanupStaleNodes(olderThan days: Int) async throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let nodes = try await loadAllNodes()
        
        for (_, node) in nodes {
            if node.lastUsed < cutoffDate {
                // Remove node and its connections
                try await deleteNode(node.id)
            }
        }
    }
    
    /// Deletes a node and its associated connections
    private func deleteNode(_ nodeId: UUID) async throws {
        // Remove the node from its batch
        let batchURL = getBatchURL(for: nodeId)
        var batchNodes = try await loadNodeBatch(at: batchURL)
        batchNodes.removeAll { $0.id == nodeId }
        try await saveNodeBatch(batchNodes, to: batchURL)
        
        // Remove associated connections
        let connections = try await loadAllConnections()
        for (_, connection) in connections {
            if connection.sourceId == nodeId || connection.targetId == nodeId {
                try await deleteConnection(connection.id)
            }
        }
    }
    
    /// Deletes a connection
    private func deleteConnection(_ connectionId: UUID) async throws {
        let batchURL = getConnectionBatchURL(for: connectionId)
        var batchConnections = try await loadConnectionBatch(at: batchURL)
        batchConnections.removeAll { $0.id == connectionId }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(batchConnections)
        try await saveFile(data: data, to: batchURL)
    }
}


/*
 
 // Different batch sizes and their implications
         let batchSizes = [
             100,    // 20KB per batch
             500,    // 100KB per batch
             1000,   // 200KB per batch
             5000,   // 1MB per batch
             10000   // 2MB per batch
         ]
 
 */
extension MetaDataStorage {
    // MARK: - Connection Storage Paths
    
    private var connectionIndexURL: URL {
        connectionsURL.appendingPathComponent("connection_index.json")
    }
    
    // MARK: - Connection Index Management
    
    /// Structure to hold connection index information
    private struct ConnectionIndex: Codable {
        // nodeId -> Set of batch IDs containing connections for this node
        var nodeConnections: [UUID: Set<Int>] = [:]
        // Last update timestamp
        var lastUpdated: Date = Date()
    }
    
    /// Updates the connection index with a new connection
    private func updateConnectionIndex(sourceId: UUID, targetId: UUID, batchId: Int) async throws {
        var index = try await loadConnectionIndex()
        
        // Update index for both source and target nodes
        index.nodeConnections[sourceId, default: []].insert(batchId)
        index.nodeConnections[targetId, default: []].insert(batchId)
        index.lastUpdated = Date()
        
        // Save updated index
        try await saveConnectionIndex(index)
    }
    
    /// Loads the connection index from disk
    private func loadConnectionIndex() async throws -> ConnectionIndex {
        if fileManager.fileExists(atPath: connectionIndexURL.path) {
            let data = try await loadFile(at: connectionIndexURL)
            return try JSONDecoder().decode(ConnectionIndex.self, from: data)
        }
        return ConnectionIndex()
    }
    
    /// Saves the connection index to disk
    private func saveConnectionIndex(_ index: ConnectionIndex) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(index)
        try await saveFile(data: data, to: connectionIndexURL)
    }
    
    // MARK: - Optimized Connection Operations
    
    /// Saves a connection using the batched approach and updates the index
    func save(connection: MetadataConnection) async throws {
        let batchId = abs(connection.id.hashValue % batchSize)
        let batchURL = getConnectionBatchURL(for: connection.id)
        
        // Load or create batch
        var batchConnections = try await loadConnectionBatch(at: batchURL)
        
        // Update or add connection
        if let index = batchConnections.firstIndex(where: { $0.id == connection.id }) {
            batchConnections[index] = connection
        } else {
            batchConnections.append(connection)
        }
        
        // Save batch
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(batchConnections)
        try await saveFile(data: data, to: batchURL)
        
        // Update index
        try await updateConnectionIndex(
            sourceId: connection.sourceId,
            targetId: connection.targetId,
            batchId: batchId
        )
    }
    
    /// Efficiently retrieves all connections for a specific node using the index
    func getConnectionsOptimized(for nodeId: UUID) async throws -> [MetadataConnection] {
        // Load index
        let index = try await loadConnectionIndex()
        
        // Get relevant batch IDs from index
        guard let batchIds = index.nodeConnections[nodeId] else {
            return []
        }
        
        // Load and filter connections from relevant batches
        var connections: [MetadataConnection] = []
        
        try await batchIds.asyncForEach { batchId in
            let batchURL = self.connectionsURL.appendingPathComponent("batch_\(batchId).json")
            let batchConnections = try await self.loadConnectionBatch(at: batchURL)
            
            // Filter connections related to this node
            let relevantConnections = batchConnections.filter {
                $0.sourceId == nodeId || $0.targetId == nodeId
            }
            
            connections.append(contentsOf: relevantConnections)
        }
        
        return connections
    }
    
    // MARK: - Index Maintenance
    
    /// Rebuilds the connection index from scratch
    func rebuildConnectionIndex() async throws {
        var index = ConnectionIndex()
        
        // Get all batch files
        let batchFiles = try fileManager.contentsOfDirectory(
            at: connectionsURL,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }
        
        // Process each batch
        try await batchFiles.asyncForEach { url in
            let batchId = Int(url.deletingPathExtension().lastPathComponent.split(separator: "_").last ?? "0") ?? 0
            let connections = try await self.loadConnectionBatch(at: url)
            
            // Update index for each connection
            for connection in connections {
                index.nodeConnections[connection.sourceId, default: []].insert(batchId)
                index.nodeConnections[connection.targetId, default: []].insert(batchId)
            }
        }
        
        // Save rebuilt index
        try await saveConnectionIndex(index)
    }
    
    /// Verifies and repairs the connection index if necessary
    func verifyConnectionIndex() async throws -> Bool {
        let index = try await loadConnectionIndex()
        
        // If index is older than 24 hours, rebuild it
        if Date().timeIntervalSince(index.lastUpdated) > 86400 {
            try await rebuildConnectionIndex()
            return false
        }
        
        return true
    }
}

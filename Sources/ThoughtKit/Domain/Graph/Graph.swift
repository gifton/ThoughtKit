//
//  File.swift
//
//
//  Created by Gifton Okoronkwo on 11/3/24.
//

import Foundation
/// Manages the in-memory cache and persistence of the metadata network
actor Graph {
    // MARK: - Properties
    
    private var nodeCache: [UUID: MetadataNode]
    private var connectionCache: [UUID: MetadataConnection]
    private let storage: GraphStorage
    private let cacheSize: Int
    
    // MARK: - Initialization
    
    init(storage: GraphStorage, cacheSize: Int = 10000) {
        self.storage = storage
        self.cacheSize = cacheSize
        self.nodeCache = [:]
        self.connectionCache = [:]
        
        // Initialize cache
        Task {
            await self.initializeCache()
        }
    }
    
    // MARK: - Cache Management
    
    private func initializeCache() async {
        // Load most recently used nodes up to cache size
        let recentNodes = try? await storage.loadAllNodes()
            .values
            .sorted { $0.lastUsed > $1.lastUsed }
            .prefix(cacheSize)
        
        recentNodes?.forEach { node in
            nodeCache[node.id] = node
        }
    }
    
    private func updateNodeCache(_ node: MetadataNode) {
        // Maintain cache size limit
        if nodeCache.count >= cacheSize {
            let oldestNode = nodeCache.values.min { $0.lastUsed < $1.lastUsed }
            if let oldest = oldestNode {
                nodeCache.removeValue(forKey: oldest.id)
            }
        }
        nodeCache[node.id] = node
    }
    
    // MARK: - Node Management
    
    
    
    /// Adds a new node or updates an existing one with the same value and type
    func addNode(_ value: String, type: NodeType, metadata: [String: Double]? = nil) async throws -> UUID {
        // Check for existing node with same value and type
        if let existingNode = await findNode(withValue: value, type: type) {
            var updatedNode = existingNode
            updatedNode.frequency += 1
            updatedNode.lastUsed = Date()
            
            // Update cache and storage
            updateNodeCache(updatedNode)
            try await storage.save(node: updatedNode)
            return existingNode.id
        }
        
        // Create new node
        let node = MetadataNode(
            id: UUID(),
            type: type,
            value: value,
            connections: [],
            createdAt: Date(),
            frequency: 1,
            lastUsed: Date(),
            statistics: metadata
        )
        
        // Update cache and storage
        updateNodeCache(node)
        try await storage.save(node: node)
        return node.id
    }
    
    // MARK: - Connection Management
    
    func connect(
        sourceId: UUID,
        targetId: UUID,
        type: MetadataRelationType,
        weight: Float,
        metadata: [String: String]? = nil
    ) async throws {
        // Verify nodes exist
        guard let _ = try await getNode(by: sourceId),
              let _ = try await getNode(by: targetId) else {
            throw Error.invalidNodes
        }
        
        // Create primary connection
        let connection = MetadataConnection(
            id: UUID(),
            sourceId: sourceId,
            targetId: targetId,
            type: type,
            weight: weight,
            createdAt: Date(),
            lastAccessed: Date(),
            metadata: metadata
        )
        
        try await storage.save(connection: connection)
        
        // Handle inverse relationships
        if let inverseType = type.inverse {
            let inverseConnection = MetadataConnection(
                id: UUID(),
                sourceId: targetId,
                targetId: sourceId,
                type: inverseType,
                weight: weight,
                createdAt: Date(),
                lastAccessed: Date(),
                metadata: metadata
            )
            
            try await storage.save(connection: inverseConnection)
        }
        
        // Handle bidirectional relationships
        if type.isBidirectional && type.inverse == nil {
            let reverseConnection = MetadataConnection(
                id: UUID(),
                sourceId: targetId,
                targetId: sourceId,
                type: type,
                weight: weight,
                createdAt: Date(),
                lastAccessed: Date(),
                metadata: metadata
            )
            
            try await storage.save(connection: reverseConnection)
        }
    }
    
    // MARK: - Node Retrieval
    
    func getNode(by id: UUID) async throws -> MetadataNode? {
        // Check cache first
        if let cachedNode = nodeCache[id] {
            return cachedNode
        }
        
        // Load from storage
        if let node = try await storage.getNode(by: id) {
            updateNodeCache(node)
            return node
        }
        
        return nil
    }
    
    // MARK: - Queries
    
    func findNode(withValue value: String, type: NodeType) async -> MetadataNode? {
        // Check cache first
        if let cachedNode = nodeCache.values.first(where: {
            $0.type == type && $0.value.lowercased() == value.lowercased()
        }) {
            return cachedNode
        }
        
        // Load from storage if not in cache
        let nodes = try? await storage.loadAllNodes()
        let foundNode = nodes?.values.first {
            $0.type == type && $0.value.lowercased() == value.lowercased()
        }
        
        if let node = foundNode {
            updateNodeCache(node)
        }
        
        return foundNode
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
    
    func findMetadata(for thoughtId: UUID, ofType type: NodeType) async throws -> [MetadataNode] {
        try await findConnections(from: thoughtId)
            .map { $0.targetId }
            .asyncConcurrentMap { id in
                try await self.getNode(by: id)
            }
            .compactMap { $0 }
            .filter { $0.type == type }
    }
    
    func findThoughts(withMetadataId metadataId: UUID) async throws -> [MetadataNode] {
        try await findConnections(from: metadataId)
            .map { $0.targetId }
            .asyncConcurrentMap { id in
                try await self.getNode(by: id)
            }
            .compactMap { $0 }
            .filter { $0.type == .thought }
    }
    
    func getMetadataDistribution(for thoughtId: UUID) async throws -> [NodeType: Int] {
        guard let connections = try? await findConnections(from: thoughtId) else {
            return [:]
        }
        
        var distribution: [NodeType: Int] = [:]
        
        for connection in connections where connection.type == .has {
            if let node = try? await getNode(by: connection.targetId) {
                distribution[node.type, default: 0] += 1
            }
        }
        
        return distribution
    }
}

// MARK: - Error Handling

extension Graph {
    enum Error: LocalizedError {
        case invalidNodes
        case connectionFailed
        case cacheError
        case queryError
    }
}

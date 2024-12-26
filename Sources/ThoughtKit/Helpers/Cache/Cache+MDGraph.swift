//
//  File.swift
//
//
//  Created by Gifton Okoronkwo on 12/23/24.
//

import Foundation

// MARK: - MetadataGraph Cache Implementation
extension MetadataGraph {
    actor GraphCache {
        private let nodeCache: LRUCache<UUID, MetadataNode>
        private let connectionCache: LRUCache<UUID, MetadataConnection>
        private let queryCache: LRUCache<String, [UUID]> // Cache for common queries
        
        init(capacity: Int) {
            self.nodeCache = LRUCache(capacity: capacity)
            self.connectionCache = LRUCache(capacity: capacity)
            self.queryCache = LRUCache(capacity: capacity / 2) // Smaller cache for queries
        }
        
        func getNode(_ id: UUID) async -> MetadataNode? {
            await nodeCache.get(id)
        }
        
        func setNode(_ node: MetadataNode) async {
            // Cost based on node complexity
            let cost = calculateNodeCost(node)
            await nodeCache.set(node.id, value: node, cost: cost)
        }
        
        func getConnection(_ id: UUID) async -> MetadataConnection? {
            await connectionCache.get(id)
        }
        
        func setConnection(_ connection: MetadataConnection) async {
            await connectionCache.set(connection.id, value: connection)
        }
        
        func cacheQuery(_ key: String, results: [UUID]) async {
            await queryCache.set(key, value: results)
        }
        
        func getCachedQuery(_ key: String) async -> [UUID]? {
            await queryCache.get(key)
        }
        
        private func calculateNodeCost(_ node: MetadataNode) -> Int {
            var cost = 1
            cost += node.connections.count
            if let embeddings = node.embeddings {
                cost += embeddings.count / 10 // Adjust cost for large embedding vectors
            }
            return cost
        }
        
        @discardableResult
        func removeNode(_ id: UUID) async -> MetadataNode? {
            await nodeCache.remove(id)
        }
        
        @discardableResult
        func removeConnection(_ id: UUID) async -> MetadataConnection? {
            await connectionCache.remove(id)
        }
        
        @discardableResult
        func removeQuery(_ key: String) async -> [UUID]? {
            await queryCache.remove(key)
        }
        
        func getCacheStats() async -> (nodes: LRUCache<UUID, MetadataNode>.CacheStats,
                                 connections: LRUCache<UUID, MetadataConnection>.CacheStats,
                                 queries: LRUCache<String, [UUID]>.CacheStats) {
            return (
                nodes: await nodeCache.getStats(),
                connections: await connectionCache.getStats(),
                queries: await queryCache.getStats()
            )
        }
    }
}

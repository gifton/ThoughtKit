//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/10/24.
//

import Foundation
import SwiftData
/// Cache actor for storing nodes and their connections
actor NodeCache {
    private struct CacheEntry {
        let node: MetadataNode
        let connections: [MetadataConnection]
        let timestamp: Date
    }
    
    private let capacity: Int
    private var cache: [UUID: CacheEntry] = [:]
    private var accessOrder: [UUID] = []
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func get(_ id: UUID) -> (node: MetadataNode, connections: [MetadataConnection])? {
        guard let entry = cache[id] else { return nil }
        
        // Update access order
        if let index = accessOrder.firstIndex(of: id) {
            accessOrder.remove(at: index)
            accessOrder.append(id)
        }
        
        return (entry.node, entry.connections)
    }
    
    func set(_ id: UUID, node: MetadataNode, connections: [MetadataConnection]) {
        // Evict oldest entry if at capacity
        if cache.count >= capacity && cache[id] == nil {
            if let oldestId = accessOrder.first {
                cache.removeValue(forKey: oldestId)
                accessOrder.removeFirst()
            }
        }
        
        // Update cache
        let entry = CacheEntry(
            node: node,
            connections: connections,
            timestamp: Date()
        )
        cache[id] = entry
        
        // Update access order
        if let index = accessOrder.firstIndex(of: id) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(id)
    }
    
    func clear() {
        cache.removeAll()
        accessOrder.removeAll()
    }
}

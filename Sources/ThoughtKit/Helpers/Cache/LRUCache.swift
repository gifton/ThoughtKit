//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/23/24.
//

import Foundation
actor LRUCache<Key: Hashable, Value> {
    private struct CacheEntry {
        let value: Value
        let key: Key
        let timestamp: Date
        let cost: Int
        var accessCount: Int
        
        mutating func markAccessed() {
            accessCount += 1
        }
    }
    
    private var entries: [Key: CacheEntry]
    private var accessOrder: [Key]
    private let capacity: Int
    private let maxCost: Int
    private var currentCost: Int
    private var stats: CacheStats
    
    struct CacheStats {
        var hits: Int = 0
        var misses: Int = 0
        var evictions: Int = 0
        var totalCost: Int = 0
        
        var hitRate: Double {
            let total = hits + misses
            return total > 0 ? Double(hits) / Double(total) : 0
        }
    }
    
    init(capacity: Int, maxCost: Int = .max) {
        self.capacity = capacity
        self.maxCost = maxCost
        self.entries = [:]
        self.accessOrder = []
        self.currentCost = 0
        self.stats = CacheStats()
    }
    
    func get(_ key: Key) async -> Value? {
        if let entry = entries[key] {
            // Update access patterns
            if let index = accessOrder.firstIndex(of: key) {
                accessOrder.remove(at: index)
            }
            accessOrder.append(key)
            
            // Update stats
            stats.hits += 1
            var updatedEntry = entry
            updatedEntry.markAccessed()
            entries[key] = updatedEntry
            
            return entry.value
        }
        
        stats.misses += 1
        return nil
    }
    
    func set(_ key: Key, value: Value, cost: Int = 1) async {
        // Ensure we can accommodate the new entry
        while currentCost + cost > maxCost || entries.count >= capacity {
            evictLeastRecentlyUsed()
        }
        
        let entry = CacheEntry(
            value: value,
            key: key,
            timestamp: Date(),
            cost: cost,
            accessCount: 0
        )
        
        // Remove old entry if it exists
        if let oldEntry = entries.removeValue(forKey: key) {
            currentCost -= oldEntry.cost
            if let index = accessOrder.firstIndex(of: key) {
                accessOrder.remove(at: index)
            }
        }
        
        // Add new entry
        entries[key] = entry
        accessOrder.append(key)
        currentCost += cost
        stats.totalCost = currentCost
    }
    
    private func evictLeastRecentlyUsed() {
        guard let lruKey = accessOrder.first else { return }
        
        if let evictedEntry = entries.removeValue(forKey: lruKey) {
            currentCost -= evictedEntry.cost
            accessOrder.removeFirst()
            stats.evictions += 1
        }
    }
    
    @discardableResult
    func remove(_ key: Key) async -> Value? {
        guard let entry = entries.removeValue(forKey: key) else {
            return nil
        }
        
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }
        
        currentCost -= entry.cost
        return entry.value
    }

    func clear() async {
        entries.removeAll()
        accessOrder.removeAll()
        currentCost = 0
        stats = CacheStats()
    }
    
    func getStats() async -> CacheStats {
        return stats
    }
}

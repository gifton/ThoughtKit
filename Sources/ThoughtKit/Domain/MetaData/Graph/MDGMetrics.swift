//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/22/24.
//

import Foundation

extension MetadataGraph {
    
    // MARK: - Metrics and Maintenance
    
    struct GraphMetrics {
        var operationCounts: [OperationType: Int] = [:]
        var errors: [ErrorType: Int] = [:]
        var lastMaintenanceDate: Date?
        var averageOperationTime: TimeInterval = 0
        
        enum OperationType {
            case nodeAddition, nodeUpdate, nodeRemoval
            case connectionAddition, connectionUpdate, connectionRemoval
            case query, traversal
        }
        
        enum ErrorType {
            case storageFailure
            case cacheInitializationFailed
            case transactionFailed
            case operationTimeout
            case nodeRetrievalFailed
            case nodeAdditionFailed
            case nodeUpdateFailed
            case nodeDeletionFailed
            case connectionAditionFailed
            case connectionUpdateFailed
            case connectionDeletionFailed
        }
        
        mutating func recordOperation(_ type: OperationType) {
            operationCounts[type, default: 0] += 1
        }
        
        mutating func recordError(_ type: ErrorType) {
            errors[type, default: 0] += 1
        }
    }
    
    // MARK: - Cache Maintenance
    func getCacheStats() async -> (
        nodes: LRUCache<UUID, MetadataNode>.CacheStats,
        connections: LRUCache<UUID, MetadataConnection>.CacheStats,
        queries: LRUCache<String, [UUID]>.CacheStats
    ) {
        await cache.getCacheStats()
    }
}

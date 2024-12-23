//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/22/24.
//

import Foundation

extension MetaDataGraph {
    
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
        }
        
        mutating func recordOperation(_ type: OperationType) {
            operationCounts[type, default: 0] += 1
        }
        
        mutating func recordError(_ type: ErrorType) {
            errors[type, default: 0] += 1
        }
    }
}

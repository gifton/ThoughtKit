//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/22/24.
//

import Foundation

extension MetaDataGraph {
    
    // MARK: - Error Types
    enum GraphError: LocalizedError {
        case transactionFailed(String)
        case invalidOperation(String)
        case nodeMissing(UUID)
        case connectionMissing(UUID)
        case storageError(Error)
        case invalidState(String)
        case operationTimeout
        case concurrencyViolation(String)
        case invalidNodeData(String)
        case cacheError(String)
        case transactionConflict(String)
        case validationError(String)
        case resourceExhausted(String)
        
        var errorDescription: String? {
            switch self {
            case .transactionFailed(let reason):
                return "Transaction failed: \(reason)"
            case .invalidOperation(let details):
                return "Invalid operation attempted: \(details)"
            case .nodeMissing(let id):
                return "Node not found with ID: \(id)"
            case .connectionMissing(let id):
                return "Connection not found with ID: \(id)"
            case .storageError(let error):
                return "Storage operation failed: \(error.localizedDescription)"
            case .invalidState(let details):
                return "Graph is in an invalid state: \(details)"
            case .operationTimeout:
                return "Operation timed out"
            case .concurrencyViolation(let details):
                return "Concurrent operation violation: \(details)"
            case .invalidNodeData(let details):
                return "Invalid node data: \(details)"
            case .cacheError(let details):
                return "Cache operation failed: \(details)"
            case .transactionConflict(let details):
                return "Transaction conflict detected: \(details)"
            case .validationError(let details):
                return "Validation failed: \(details)"
            case .resourceExhausted(let details):
                return "Resource limit reached: \(details)"
            }
        }
    }
}

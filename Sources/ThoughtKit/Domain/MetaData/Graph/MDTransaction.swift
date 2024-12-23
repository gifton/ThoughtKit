//
//  MDTransaction.swift
//
//
//  Created by Gifton Okoronkwo on 12/23/24.
//

import Foundation

extension MetadataGraph {
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
            
            var metric: GraphMetrics.OperationType {
                switch self {
                case .addNode(let metadataNode): .nodeAddition
                case .updateNode(let metadataNode): .nodeUpdate
                case .deleteNode(let uUID): .nodeRemoval
                case .addConnection(let metadataConnection): .connectionAddition
                case .updateConnection(let metadataConnection): .connectionUpdate
                case .deleteConnection(let uUID): .connectionRemoval
                }
            }
            
            var errorMetric: GraphMetrics.ErrorType {
                switch self {
                case .addNode(_ ): .nodeAdditionFailed
                case .updateNode(_): .nodeUpdateFailed
                case .deleteNode(let uUID): .nodeDeletionFailed
                case .addConnection(_): .connectionAditionFailed
                case .updateConnection(_): .connectionUpdateFailed
                case .deleteConnection(_): .connectionDeletionFailed
                }
            }
        }
        
        var metrics: [GraphMetrics.OperationType] {
            self.operations.map { $0.metric }
        }
    }

}

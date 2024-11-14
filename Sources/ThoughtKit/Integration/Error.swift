//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation
enum IntegratedSystemError: Error {
    case nodeNotFound(UUID)
    case invalidNodeType(NodeType)
    case processingFailed(String)
    case invalidPattern(String)
    case contextMismatch(String)
    case relationshipError(String)
}

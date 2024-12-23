//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/21/24.
//

import Foundation

extension MDResult {
    // Decision points
    struct Decision: MetaData {
        let value: String
        let confidenceScore: Float
        let sourcePosition: Range<Int>?
        let frequency: Int
        
        // Decision specifics
        let type: DecisionType
        let options: [String]
        let outcome: String?
        let reasoning: [String]?
        let impact: Impact
        let certainty: Float  // 0.0 to 1.0
        
        var nodeType: NodeType { .decision }
        
        enum DecisionType {
            case major     // Life-changing
            case moderate  // Significant but not life-changing
            case minor    // Day-to-day
            case recurring // Regular decisions
        }
        
        enum Impact {
            case personal
            case professional
            case financial
            case relationship
            case health
            case multiple([Impact])
        }
    }
}

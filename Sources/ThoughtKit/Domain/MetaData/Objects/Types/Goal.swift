//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/21/24.
//

import Foundation

extension MDResult {
    
    // Goal/Intention references
    struct Goal: MetaData {
        let value: String
        let confidenceScore: Float
        let sourcePosition: Range<Int>?
        let frequency: Int
        
        // Goal specifics
        let type: GoalType
        let timeframe: TimeFrame?
        let status: Status
        let priority: Float  // 0.0 to 1.0
        let dependencies: [String]?
        
        var nodeType: NodeType { .goal }
        
        enum GoalType {
            case personal
            case professional
            case health
            case financial
            case learning
            case relationship
            case project
        }
        
        enum TimeFrame {
            case immediate
            case shortTerm(days: Int)
            case mediumTerm(weeks: Int)
            case longTerm(months: Int)
            case ongoing
        }
        
        enum Status {
            case planned
            case inProgress
            case completed
            case abandoned
            case delayed
        }
    }
    
    
}

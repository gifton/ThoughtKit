//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/21/24.
//

import Foundation

extension MDResult{
    // Problem/Challenge references
    struct Challenge: MetaData {
        let value: String
        let confidenceScore: Float
        let sourcePosition: Range<Int>?
        let frequency: Int
        
        // Challenge specifics
        let type: ChallengeType
        let severity: Float  // 0.0 to 1.0
        let status: Status
        let solutions: [String]?
        let relatedChallenges: [String]?
        
        var nodeType: NodeType { .challenge }
        
        enum ChallengeType {
            case personal
            case professional
            case technical
            case emotional
            case interpersonal
            case health
            case financial
        }
        
        enum Status {
            case active
            case resolved
            case ongoing
            case avoided
        }
    }
}

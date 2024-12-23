//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/21/24.
//

import Foundation

extension MDResult {
    // Resource references
    struct Resource: MetaData {
        let value: String
        let confidenceScore: Float
        let sourcePosition: Range<Int>?
        let frequency: Int
        
        // Resource specifics
        let type: ResourceType
        let availability: Availability
        let importance: Float  // 0.0 to 1.0
        let constraints: [String]?
        let alternatives: [String]?
        
        var nodeType: NodeType { .resource }
        
        enum ResourceType {
            case time
            case financial
            case human
            case material
            case information
            case digital
            case emotional
        }
        
        enum Availability {
            case available
            case limited
            case unavailable
            case scheduled(Date)
        }
    }
}

//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/21/24.
//

import Foundation

extension MDResult {
    // Time-based metadata
    struct TimeReference: MetaData {
        let value: String
        let confidenceScore: Float
        let sourcePosition: Range<Int>?
        let frequency: Int
        
        // Temporal specifics
        let dateTime: Date?
        let precision: TemporalPrecision
        let timeType: TimeType
        let isRelative: Bool  // e.g., "yesterday", "next week"
        let duration: TimeInterval?
        
        var nodeType: NodeType { .timeReference }
        
        enum TemporalPrecision {
            case exact      // "3:30 PM on June 1st, 2024"
            case hour      // "around 3 PM"
            case dayTime   // "morning", "evening"
            case day       // "yesterday"
            case week      // "last week"
            case month     // "in March"
            case season    // "last summer"
            case year      // "2023"
            case decade    // "the 90s"
        }
        
        enum TimeType {
            case point     // Specific moment
            case period    // Duration
            case recurring // Regular intervals
            case deadline  // Due dates
            case relative  // Relative to now
        }
    }
}

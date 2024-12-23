//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

struct TemporalContext: Hashable, Codable {
    // Core temporal properties
    var timestamp: Date
    var duration: TimeInterval?
    var range: ClosedRange<Date>?
    
    // Relative timing
    var recurrence: RecurrencePattern?
    var sequence: SequenceInfo?
    
    // Time-based relationships
    var precedingEvents: Set<UUID>?
    var followingEvents: Set<UUID>?
    var concurrent: Set<UUID>?
    
    // Temporal metadata
    var timeZone: TimeZone
    var precision: TemporalPrecision
    var confidence: Float
    
    enum TemporalPrecision: Hashable, Codable {
        case exact          // Precise timestamp
        case hourly        // Within the hour
        case daily         // Within the day
        case weekly        // Within the week
        case monthly       // Within the month
        case quarterly     // Within the quarter
        case yearly        // Within the year
        case approximate   // General timeframe
    }
    
    struct RecurrencePattern: Hashable, Codable {
        var frequency: Frequency
        var interval: Int
        var endDate: Date?
        var occurrences: Int?
        
        enum Frequency: Hashable, Codable {
            case daily
            case weekly
            case monthly
            case yearly
            case custom(TimeInterval)
        }
    }
    
    struct SequenceInfo: Hashable, Codable {
        var order: Int
        var totalInSequence: Int?
        var sequenceID: UUID
        var isComplete: Bool
    }
}

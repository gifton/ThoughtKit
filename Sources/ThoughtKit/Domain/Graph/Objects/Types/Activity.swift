//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/9/24.
//

import Foundation

extension MDResult {
    // Activity metadata
    struct Activity: MDItem {
        let value: String
        let confidenceScore: Float
        let sourcePosition: Range<Int>?
        let frequency: Int
        let tense: Tense  // enum: past, present, future
        let duration: TimeInterval?  // Estimated duration if applicable
        let isRecurring: Bool  // Whether it's a recurring activity
        
        var nodeType: NodeType { .activity }
    }
    
    // general temporal reference
    enum Tense: String {
        case past, present, future
    }
}

extension MDResult {
    // Activity metadata
    struct Event: MDItem {
        let value: String
        let confidenceScore: Float
        let sourcePosition: Range<Int>?
        let frequency: Int
        
        var nodeType: NodeType { .event }
    }
}

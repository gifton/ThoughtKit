//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/9/24.
//

import Foundation



extension MDResult {
    struct Summary: MetaData {
        var value: String { summary }
        
        var confidenceScore: Float
        var sourcePosition: Range<Int>? = nil
        var frequency: Int = 0
        
        enum Length {
            case short
            case medium
            case long
        }
        
        var preffered: Length
        var short: String
        var medium: String
        var long: String
        
        var summary: String {
            switch preffered {
            case .short: return short
            case .medium: return medium
            case .long: return long
            }
        }
        
        var nodeType: NodeType { .summary}
    }
}

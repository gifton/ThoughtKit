//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/9/24.
//

import Foundation

extension MDResult {
    // Topic metadata
    struct Topic: MetaData {
        let value: String
        let confidenceScore: Float
        let sourcePosition: Range<Int>?
        let frequency: Int
        let hierarchyLevel: Int  // Depth in topic hierarchy (0 for main topics)
        let parentTopic: String?  // Parent topic if it's a subtopic
        
        var nodeType: NodeType { .topic }
    }

}


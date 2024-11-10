//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/9/24.
//

import Foundation

extension MDResult{
    // Keyword metadata
    struct Keyword: MDItem {
        let value: String
        let confidenceScore: Float
        let sourcePosition: Range<Int>?
        let frequency: Int
        let importance: Float  // TF-IDF score or similar relevance metric
        let isCompound: Bool  // Whether it's a multi-word keyword
        
        var nodeType: NodeType { .keyword }
    }
}

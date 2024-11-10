//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/9/24.
//

import Foundation

extension MDResult {
    // Person metadata
    struct Person: MetaData {
        let value: String
        let confidenceScore: Float
        let sourcePosition: Range<Int>?
        let frequency: Int
        let role: String?  // Role or relationship in the context
        let salience: Float  // 0.0 to 1.0 importance in the text
        let isProperNoun: Bool  // Whether it's a specific named person
        
        var nodeType: NodeType { .person }
    }
}

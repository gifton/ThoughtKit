//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/9/24.
//

import Foundation

extension MDResult{
    // Emotion metadata
    struct Emotion: MDItem {
        let value: String
        let confidenceScore: Float
        let sourcePosition: Range<Int>?
        let frequency: Int
        let intensity: Float  // 0.0 to 1.0 intensity of the emotion
        let valence: Float  // -1.0 to 1.0 for negative to positive
        let arousal: Float  // 0.0 to 1.0 for calm to excited
        
        var nodeType: NodeType { .emotion }
    }
}

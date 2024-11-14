//
//  ThoughtPattern.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

struct ThoughtPattern {
    let id: UUID
    var nodes: Set<UUID>
    var strength: Float
    var confidence: Float
    var patternType: PatternType
    var metadata: PatternMetadata
}

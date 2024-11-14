//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

struct SystemInsight {
    let id: UUID
    var source: InsightSource
    var confidence: Float
    var description: String
    var relatedNodes: Set<UUID>
    var context: InsightContext
}

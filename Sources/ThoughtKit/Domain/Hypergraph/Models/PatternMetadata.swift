//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

struct PatternMetadata: Hashable {
    var createdAt: Date
    var lastUpdated: Date
    var frequency: Int
    var stability: Float
    var source: PatternSource
}

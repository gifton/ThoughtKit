//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

enum PatternType {
    case semantic(embedding: [Float])
    case temporal(interval: TimeInterval)
    case categorical(categories: Set<String>)
    case emotional(valence: Float, arousal: Float)
    case spatial(coordinates: [Float])
}

//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

struct NeuralMatch {
    let neuronId: UUID
    var strength: Float
    var confidence: Float
    var pattern: PatternType
    var context: NeuralContext
}

//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation
struct NeuralContext: Hashable {
    var activation: Float
    var threshold: Float
    var decay: Float
    var lastFired: Date
}

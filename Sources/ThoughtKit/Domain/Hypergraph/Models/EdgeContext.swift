//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

struct EdgeContext {
    var temporal: TemporalContext?
    var semantic: SemanticContext?
    var confidence: Float
    var metadata: [String: Any]
}

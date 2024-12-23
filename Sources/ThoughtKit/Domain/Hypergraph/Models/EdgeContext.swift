//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

public struct EdgeContext: Hashable, Codable {
    var temporal: TemporalContext?
    var semantic: SemanticContext?
    var confidence: Float
    var metadata: TypedMetadata
}

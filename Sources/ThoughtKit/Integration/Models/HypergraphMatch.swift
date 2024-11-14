//
//  HypergraphMatch.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

struct HypergraphMatch {
    let edgeId: UUID
    var nodes: Set<UUID>
    var strength: Float
    var context: EdgeContext
    var metadata: EdgeMetadata
}

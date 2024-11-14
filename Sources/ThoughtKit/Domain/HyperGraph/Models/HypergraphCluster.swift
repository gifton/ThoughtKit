//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation
struct HypergraphCluster {
    let id: UUID
    var edges: Set<UUID>
    var centralNode: UUID?
    var strength: Float
    var context: ClusterContext
}

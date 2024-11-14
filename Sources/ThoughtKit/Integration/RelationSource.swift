//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

enum RelationSource: Hashable {
    case explicit(type: MetadataRelationType)
    case neural(strength: Float)
    case hypergraph(edgeId: UUID)
    case derived(method: String)
}

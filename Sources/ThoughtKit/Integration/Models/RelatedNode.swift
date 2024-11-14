//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

struct RelatedNode {
    let nodeId: UUID
    var nodeType: NodeType
    var relationTypes: Set<MetadataRelationType>
    var strength: Float
    var confidence: Float
    var sources: Set<RelationSource>
}

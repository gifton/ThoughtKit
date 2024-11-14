//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

struct QueryContext {
    var temporalRange: ClosedRange<Date>?
    var semanticContext: Set<String>
    var confidence: Float
    var maxResults: Int
    var includeTypes: Set<NodeType>
    var relationTypes: Set<MetadataRelationType>
}

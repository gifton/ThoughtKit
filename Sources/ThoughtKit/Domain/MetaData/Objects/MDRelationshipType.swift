//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/6/24.
//

import Foundation

public typealias MDRelationType = MetadataRelationType
/// Defines the types of relationships between metadata nodes
public enum MetadataRelationType: String, Codable, Hashable {
    // Core relationships
    case has           // Base relationship (thought has keyword)
    case relatedTo    // General relationship
    
    // Hierarchical relationships
    case parentOf
    case childOf
    case partOf      // Component relationship
    
    // Semantic relationships
    case synonym
    case antonym
    case broader     // More general concept
    case narrower    // More specific concept
    
    // Statistical relationships
    case coOccurs    // Frequently appear together
    case correlates  // Statistically related
    case precedes    // Temporal relationship
    case follows     // Temporal relationship
    
    /// Returns the inverse relationship type if one exists
    var inverse: MetadataRelationType? {
        switch self {
        case .parentOf: return .childOf
        case .childOf: return .parentOf
        case .broader: return .narrower
        case .narrower: return .broader
        case .precedes: return .follows
        case .follows: return .precedes
        case .has, .relatedTo, .synonym, .antonym, .coOccurs, .correlates, .partOf:
            return nil
        }
    }
    
    /// Whether this relationship type is bidirectional
    var isBidirectional: Bool {
        switch self {
        case .relatedTo, .synonym, .antonym, .coOccurs, .correlates:
            return true
        case .has, .parentOf, .childOf, .broader, .narrower, .precedes, .follows, .partOf:
            return false
        }
    }
}

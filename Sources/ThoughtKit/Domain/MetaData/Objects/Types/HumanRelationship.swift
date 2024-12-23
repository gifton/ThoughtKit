//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/21/24.
//

import Foundation

extension MDResult {
    // Relationship references
    struct HumanRelationship: MetaData {
        let value: String
        let confidenceScore: Float
        let sourcePosition: Range<Int>?
        let frequency: Int
        
        // Relationship specifics
        let type: RelationType
        let parties: [String]  // Names/identifiers of involved parties
        let sentiment: Float   // -1.0 to 1.0
        let intensity: Float   // 0.0 to 1.0 for relationship strength
        let isReciprocal: Bool
        
        var nodeType: NodeType { .humanRelationship }
        
        enum RelationType {
            case family(FamilyRelation)
            case friendship
            case romantic
            case professional
            case acquaintance
            case mentor
            case peer
            case custom(String)
            
            enum FamilyRelation {
                case parent, child, sibling, spouse
                case extendedFamily(String)
            }
        }
    }

}

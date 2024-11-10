//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/9/24.
//

import Foundation
import SwiftData

@Model
public final class Category: Codable {
    public var id: UUID
    var name: String
    var info: String?
    var createdAt: Date
    var thoughts: [Thought]
    
    // Parent-child relationship
    var parent: Category?
    var subcategories: [Category]
    
    init(name: String, info: String? = nil) {
        self.id = UUID()
        self.name = name
        self.info = info
        self.createdAt = Date()
        self.thoughts = []
        self.subcategories = []
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, info, createdAt
        case thoughtIds, parentId, subcategoryIds
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode basic properties
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(info, forKey: .info)
        try container.encode(createdAt, forKey: .createdAt)
        
        // Encode relationships as IDs
        let thoughtIds = thoughts.map { $0.id }
        try container.encode(thoughtIds, forKey: .thoughtIds)
        
        try container.encodeIfPresent(parent?.id, forKey: .parentId)
        
        let subcategoryIds = subcategories.map { $0.id }
        try container.encode(subcategoryIds, forKey: .subcategoryIds)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode basic properties
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        info = try container.decodeIfPresent(String.self, forKey: .info)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // Initialize empty arrays and nil relationships
        thoughts = []
        subcategories = []
        parent = nil
    }
}

//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/9/24.
//

import Foundation
import SwiftData

@Model
public final class Tag: Codable {
    public var id: UUID
    var name: String
    var createdAt: Date
    var thoughts: [Thought]
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.thoughts = []
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, createdAt, thoughtIds
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        
        // Encode thought relationships as IDs
        let thoughtIds = thoughts.map { $0.id }
        try container.encode(thoughtIds, forKey: .thoughtIds)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // Initialize empty array for thoughts
        thoughts = []
    }
}

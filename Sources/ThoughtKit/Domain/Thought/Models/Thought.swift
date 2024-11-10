//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/2/24.
//

import SwiftData
import Foundation

@Model
public final class Thought: Codable {
    // MARK: - Core Properties
    public var id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Metadata Status
    var isAnalyzed: Bool
    var lastAnalyzedAt: Date?
    var analysisVersion: Int
    
    // MARK: - Core Metadata
    var title: String?
    var summary: String?
    var sentiment: Double?  // -1.0 to 1.0
    
    // MARK: - Tags and Categories
    @Relationship(deleteRule: .nullify, inverse: \Tag.thoughts)
    var tags: [Tag]
    
    @Relationship(deleteRule: .nullify, inverse: \Category.thoughts)
    var categories: [Category]
    
    // MARK: - Related Thoughts
    // Use only one @Relationship for self-referential relationships
    @Relationship(.unique)
    var relatedThoughts: [Thought]
    var relatedToMe: [Thought]
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id, content, createdAt, updatedAt
        case isAnalyzed, lastAnalyzedAt, analysisVersion
        case title, summary, sentiment
        case tagIds, categoryIds
        case relatedThoughtIds, relatedToMeIds
    }
    
    // MARK: - Initialization
    init(content: String) {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isAnalyzed = false
        self.analysisVersion = 1
        self.tags = []
        self.categories = []
        self.relatedThoughts = []
        self.relatedToMe = []
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode core properties
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Decode metadata status
        isAnalyzed = try container.decode(Bool.self, forKey: .isAnalyzed)
        lastAnalyzedAt = try container.decodeIfPresent(Date.self, forKey: .lastAnalyzedAt)
        analysisVersion = try container.decode(Int.self, forKey: .analysisVersion)
        
        // Decode core metadata
        title = try container.decodeIfPresent(String.self, forKey: .title)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        sentiment = try container.decodeIfPresent(Double.self, forKey: .sentiment)
        
        // Initialize empty arrays for relationships
        tags = []
        categories = []
        relatedThoughts = []
        relatedToMe = []
    }
}

// MARK: - Codable Conformance
extension Thought {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode core properties
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        // Encode metadata status
        try container.encode(isAnalyzed, forKey: .isAnalyzed)
        try container.encodeIfPresent(lastAnalyzedAt, forKey: .lastAnalyzedAt)
        try container.encode(analysisVersion, forKey: .analysisVersion)
        
        // Encode core metadata
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(summary, forKey: .summary)
        try container.encodeIfPresent(sentiment, forKey: .sentiment)
        
        // Encode relationships as arrays of IDs
        try container.encode(tags.map { $0.id }, forKey: .tagIds)
        try container.encode(categories.map { $0.id }, forKey: .categoryIds)
        try container.encode(relatedThoughts.map { $0.id }, forKey: .relatedThoughtIds)
        try container.encode(relatedToMe.map { $0.id }, forKey: .relatedToMeIds)
    }
}

// MARK: - Relationship Management
extension Thought {
    func addRelatedThought(_ thought: Thought) {
        if !relatedThoughts.contains(where: { $0.id == thought.id }) {
            relatedThoughts.append(thought)
            thought.relatedToMe.append(self)
            updatedAt = Date()
        }
    }
    
    func removeRelatedThought(_ thought: Thought) {
        relatedThoughts.removeAll { $0.id == thought.id }
        thought.relatedToMe.removeAll { $0.id == self.id }
        updatedAt = Date()
    }
    
    /// Restores relationships after decoding using the stored IDs
    func restoreRelationships(
        tagIds: [UUID],
        categoryIds: [UUID],
        relatedThoughtIds: [UUID],
        relatedToMeIds: [UUID],
        context: ModelContext
    ) async throws {
        // Restore tags
        let tagDescriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tagIds.contains($0.id) }
        )
        self.tags = try context.fetch(tagDescriptor)
        
        // Restore categories
        let categoryDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { categoryIds.contains($0.id) }
        )
        self.categories = try context.fetch(categoryDescriptor)
        
        // Restore related thoughts
        let relatedDescriptor = FetchDescriptor<Thought>(
            predicate: #Predicate<Thought> { relatedThoughtIds.contains($0.id) }
        )
        self.relatedThoughts = try context.fetch(relatedDescriptor)
        
        // Restore related to me
        let relatedToMeDescriptor = FetchDescriptor<Thought>(
            predicate: #Predicate<Thought> { relatedToMeIds.contains($0.id) }
        )
        self.relatedToMe = try context.fetch(relatedToMeDescriptor)
    }
}
// MARK: - Relationship Restoration Helper
extension Thought {
    /// Restores relationships after decoding using the stored IDs
    func restoreRelationships(
        tagIds: [UUID],
        categoryIds: [UUID],
        relatedThoughtIds: [UUID],
        context: ModelContext
    ) async throws {
        // Restore tags
        let tagDescriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tagIds.contains($0.id) }
        )
        self.tags = try context.fetch(tagDescriptor)
        
        // Restore categories
        let categoryDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { categoryIds.contains($0.id) }
        )
        self.categories = try context.fetch(categoryDescriptor)
        
        // Restore related thoughts
        let thoughtDescriptor = FetchDescriptor<Thought>(
            predicate: #Predicate<Thought> { relatedThoughtIds.contains($0.id) }
        )
        self.relatedThoughts = try context.fetch(thoughtDescriptor)
    }
}


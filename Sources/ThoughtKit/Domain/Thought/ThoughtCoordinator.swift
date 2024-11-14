//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/3/24.
//

import Foundation
import CoreData
import SwiftData

/// Main coordinator for thought processing and metadata management
class ThoughtCoordinator {
    private let graph: MetaDataGraph
    private let mapper: MetaDataMapper
    
    init() throws {
        // Initialize the storage and network components
        let storage = try MetaDataStorage()
        self.graph = .init(storage: storage)
        self.mapper = MetaDataMapper(graph: graph)
    }
    
    /// Process a new or updated thought
    func processThought(_ thought: Thought) async throws {
        // Let the mapper handle all metadata extraction and storage
        try await mapper.processThought(thought.id, content: thought.content)
    }
    
    /// Retrieve organized metadata for a thought
    func getThoughtMetadata(_ thoughtId: UUID) async throws -> ThoughtMetadata {
        try await mapper.getThoughtMetadata(thoughtId)
    }
    
    /// Find related thoughts based on shared metadata
    func findRelatedThoughts(_ thoughtId: UUID) async throws -> [UUID] {
        try await mapper.findRelatedThoughts(thoughtId)
    }
}


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
    private let semNet: MetadataNetworkStore
    private let mapper: NetworkMapper
    
    init() throws {
        // Initialize the storage and network components
        let storage = try NetworkStorageManager()
        self.semNet = MetadataNetworkStore(storage: storage)
        self.mapper = NetworkMapper(store: semNet)
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

class ThoughtManager {
    private let coordinator: ThoughtCoordinator
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init() throws {
        // Initialize SwiftData
        let schema = Schema([Thought.self, Tag.self, Category.self])
        let modelConfiguration = ModelConfiguration(schema: schema)
        self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        self.modelContext = ModelContext(modelContainer)
        
        // Initialize coordinator
        self.coordinator = try ThoughtCoordinator()
    }
    
    func saveThought(_ content: String) async throws {
        // Create and save SwiftData thought
        let thought = Thought(content: content)
        modelContext.insert(thought)
        
        try? modelContext.save()
        
        // Process metadata
        try await coordinator.processThought(thought)
    }
    
    func getRelatedThoughts(_ thoughtId: UUID) async throws -> [Thought] {
        // Get related thought IDs from metadata network
        let relatedIds = try await coordinator.findRelatedThoughts(thoughtId)
        
        // Fetch thoughts using SwiftData
        let descriptor = FetchDescriptor<Thought>(
            predicate: #Predicate<Thought> { thought in
                relatedIds.contains(thought.id)
            }
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func getThoughtMetadata(_ thoughtId: UUID) async throws -> ThoughtMetadata {
        try await coordinator.getThoughtMetadata(thoughtId)
    }
}

//
//// Example usage in a view:
//class ThoughtDetailView: UIViewController {
//    private let thoughtManager = ThoughtManager()
//    private var thought: Thought
//    
//    func updateMetadataDisplay() async {
//        let metadata = await thoughtManager.getThoughtMetadata(thought.id)
//        
//        // Update UI with organized metadata
//        keywordsLabel.text = metadata.keywords.map(\.value).joined(separator: ", ")
//        topicsLabel.text = metadata.topics.map(\.value).joined(separator: ", ")
//        peopleLabel.text = metadata.people.map(\.value).joined(separator: ", ")
//        // etc...
//        
//        // Get related thoughts
//        let relatedThoughts = await thoughtManager.getRelatedThoughts(thought.id)
//        // Update related thoughts UI...
//    }
//}

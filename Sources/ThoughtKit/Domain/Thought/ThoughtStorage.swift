//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/10/24.
//

import Foundation
import SwiftData

actor ThoughtStorage {
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

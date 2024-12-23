//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/3/24.
//

import Foundation

/// Manages the mapping and organization of metadata for thoughts
/// Provides high-level operations for working with thought metadata
///

/**
GraphProcessor manages high-level metadata extraction and organization for thoughts. Key responsibilities:

- Coordinates metadata extraction from thought content
- Manages metadata classification and storage
- Handles bidirectional mapping between thoughts and metadata
- Provides abstracted metadata querying and retrieval
- Orchestrates relationship inference between metadata nodes

Processing pipeline:
1. Content analysis (keywords, topics, entities, etc)
2. Metadata node creation and classification
3. Relationship inference through GraphBuilder
4. Persistent storage and cache management
5. Query interface for metadata retrieval

Uses natural language processing for extraction and maintains metadata type safety through generics.
Thread-safe through actor isolation.
*/

actor GraphProcessor {

    private let graph: MetadataGraph
    private let builder: GraphBuilder

    init(graph: MetadataGraph) {
        self.graph = graph
        self.builder = GraphBuilder(graph: graph)
    }

    /// Processes a thought by creating metadata nodes, connecting them, and establishing relationships
    func processThought(_ thoughtId: UUID, content: String) async throws {
        do {
            // Generate metadata results using the factory pattern
            let results: MetaDataResult = try await .factory { nodeType in
                switch nodeType {
                case .keyword: return try await extractKeywords(from: content)
                case .activity: return try await inferActivities(from: content)
                case .location: return try await extractLocations(from: content)
                case .topic: return try await inferTopics(from: content)
                case .timeReference: return try await extractTimeReferences(from: content)
                case .person: return try await extractPeople(from: content)
                case .emotion: return try await analyzeEmotions(in: content)
                default: return []
                }
            }

            // Process relationships using the relationship builder
            try await builder.processRelationships(thoughtId: thoughtId, result: results)

        } catch let error as MetadataGraph.GraphError {
            // Log and handle graph-specific errors
            print("Graph error: \(error.localizedDescription)")
            throw error
        } catch {
            // Handle generic errors
            print("Unexpected error: \(error.localizedDescription)")
            throw error
        }
    }

    /// Retrieves all metadata for a thought organized by type
    func getThoughtMetadata(_ thoughtId: UUID) async throws -> ThoughtMetadata {
        var metadata = ThoughtMetadata()

        metadata.keywords = try await graph.findMetadata(for: thoughtId, ofType: .keyword)
        metadata.topics = try await graph.findMetadata(for: thoughtId, ofType: .topic)
        metadata.emotions = try await graph.findMetadata(for: thoughtId, ofType: .emotion)
        metadata.locations = try await graph.findMetadata(for: thoughtId, ofType: .location)
        metadata.people = try await graph.findMetadata(for: thoughtId, ofType: .person)
        metadata.activities = try await graph.findMetadata(for: thoughtId, ofType: .activity)

        return metadata
    }

    /// Finds thoughts related to a given thought based on shared metadata
    func findRelatedThoughts(_ thoughtId: UUID, minSimilarity: Float = 0.3) async throws -> [UUID] {
        // Get all metadata for the thought
        let metadata = try await getThoughtMetadata(thoughtId)
        let allMetadataIds = metadata.allNodes.map { $0.id }

        // Find thoughts that share this metadata
        var relatedThoughtIds = Set<UUID>()
        for metadataId in allMetadataIds {
            let relatedThoughts = try await graph.findThoughts(withMetadataId: metadataId)
            relatedThoughtIds.formUnion(relatedThoughts.map { $0.id })
        }

        // Remove the original thought
        relatedThoughtIds.remove(thoughtId)

        return Array(relatedThoughtIds)
    }
}

extension GraphProcessor {
    // MARK: - Metadata Extraction Methods

    private func extractKeywords(from content: String) async throws -> [MDResult.Keyword] {
        // Implement keyword extraction using NLP
        return []
    }

    private func inferTopics(from content: String) async throws -> [MDResult.Topic] {
        // Implement topic inference
        return []
    }

    private func analyzeEmotions(in content: String) async throws -> [MDResult.Emotion] {
        // Implement emotion analysis
        return []
    }

    private func extractLocations(from content: String) async throws -> [MDResult.Location] {
        // Implement location extraction
        return []
    }

    private func extractPeople(from content: String) async throws -> [MDResult.Person] {
        // Implement person name extraction
        return []
    }

    private func inferActivities(from content: String) async throws -> [MDResult.Activity] {
        // Implement activity inference
        return []
    }

    private func extractTimeReferences(from content: String) async throws -> [MDResult.TimeReference] {
        // Implement time reference extraction
        return []
    }
}

/// Structure to hold organized metadata for a thought
struct ThoughtMetadata {
    var keywords: [MetadataNode] = []
    var topics: [MetadataNode] = []
    var emotions: [MetadataNode] = []
    var locations: [MetadataNode] = []
    var people: [MetadataNode] = []
    var activities: [MetadataNode] = []

    var allNodes: [MetadataNode] {
        keywords + topics + emotions + locations + people + activities
    }
}

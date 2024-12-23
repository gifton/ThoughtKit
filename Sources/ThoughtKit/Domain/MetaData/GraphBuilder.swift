
//
//  RelationshipManager.swift
//
//
//  Created by Gifton Okoronkwo on 11/9/24.
//

import Foundation


/// owns creation of relationships between nodes of a newly creates thought
///  also owns adding new relationship
///  TODO: confirm addition of relationship is sent through builder

/**
GraphBuilder manages relationship creation and maintenance between metadata nodes. Core features:

- Configurable relationship rules based on node types and content
- Temporal and spatial relationship detection
- Weight calculation based on multiple factors
- Batch relationship processing for performance
- Transaction support for atomic operations

Relationship types:
- Direct connections between metadata nodes
- Co-occurrence based on content proximity
- Hierarchical relationships (parent/child)
- Temporal sequences and dependencies
- Semantic relationships based on meaning

Uses a rule-based system for relationship inference with support for custom rules.
All operations are transactional and thread-safe through actor isolation.
*/

/// Manages the creation and maintenance of relationships between metadata nodes
final actor GraphBuilder {
    // MARK: - Dependencies
    private let graph: MetadataGraph
    
    // MARK: - Relationship Rules
    private struct RelationshipRule {
        let sourceType: NodeType
        let targetType: NodeType
        let relationType: MetadataRelationType
        let baseWeight: Float
        let condition: (MetaData, MetaData) -> Bool
        let weightModifier: ((MetaData, MetaData) -> Float)?
    }
    
    // MARK: - Private Properties
    private var relationshipRules: [RelationshipRule]
    
    // MARK: - Initialization
    
    /// Creates a relationship builder with a specific metadata graph
    /// - Parameter graph: The metadata graph to build relationships in
    init(graph: MetadataGraph) {
        self.graph = graph
        self.relationshipRules = Self.defaultRelationshipRules()
    }
    
    // MARK: - Default Relationship Rules
    
    /// Generates a set of default relationship inference rules
    /// - Returns: An array of predefined relationship rules
    private static func defaultRelationshipRules() -> [RelationshipRule] {
        return [
            // Keywords co-occurrence rule
            RelationshipRule(
                sourceType: .keyword,
                targetType: .keyword,
                relationType: .coOccurs,
                baseWeight: 0.5
            ) { keyword1, keyword2 in
                guard let pos1 = keyword1.sourcePosition,
                      let pos2 = keyword2.sourcePosition else { return false }
                // Consider keywords co-occurring if within 50 characters
                return abs(pos1.lowerBound - pos2.lowerBound) < 50
            } weightModifier: { keyword1, keyword2 in
                // Weight based on proximity and combined confidence
                (keyword1.confidenceScore + keyword2.confidenceScore) / 2
            },
            
            // Topics hierarchy rule
            RelationshipRule(
                sourceType: .topic,
                targetType: .topic,
                relationType: .parentOf,
                baseWeight: 0.8
            ) { topic1, topic2 in
                guard let t1 = topic1 as? MDResult.Topic,
                      let t2 = topic2 as? MDResult.Topic else { return false }
                // Create hierarchy based on topic levels
                return t1.hierarchyLevel < t2.hierarchyLevel &&
                       t2.parentTopic == t1.value
            } weightModifier: { topic1, topic2 in
                // Higher confidence for more direct parent-child relationships
                (topic1.confidenceScore + topic2.confidenceScore) / 2
            },
            
            // Keywords to Topics relationship
            RelationshipRule(
                sourceType: .keyword,
                targetType: .topic,
                relationType: .partOf,
                baseWeight: 0.7
            ) { keyword, topic in
                // Keywords are part of topics if they appear in the topic text
                topic.value.localizedStandardContains(keyword.value)
            } weightModifier: { keyword, topic in
                // Weight based on confidence and frequency
                Float(keyword.frequency) * keyword.confidenceScore * topic.confidenceScore
            },
            
            // Sequential Activities rule
            RelationshipRule(
                sourceType: .activity,
                targetType: .activity,
                relationType: .precedes,
                baseWeight: 0.6
            ) { activity1, activity2 in
                guard let pos1 = activity1.sourcePosition,
                      let pos2 = activity2.sourcePosition else { return false }
                // Activities are sequential if they appear in order within reasonable distance
                return pos1.upperBound < pos2.lowerBound &&
                       pos2.lowerBound - pos1.upperBound < 100
            } weightModifier: { activity1, activity2 in
                // Weight based on proximity and confidence
                activity1.confidenceScore * activity2.confidenceScore
            }
        ]
    }
    
    // MARK: - Relationship Processing
    
    /// Processes relationships for a thought based on its metadata
    /// - Parameters:
    ///   - thoughtId: The unique identifier of the thought
    ///   - result: Metadata result containing various node types
    func processRelationships(thoughtId: UUID, result: MetaDataResult) async throws {
        // Begin a transaction to ensure atomic relationship creation
        let transactionId = try await graph.beginTransaction()
        
        do {
            // Create nodes for all metadata items
            let nodeIds = try await createNodes(from: result)
            
            // Connect metadata to the thought
            try await connectMetadataToThought(thoughtId: thoughtId, nodeIds: nodeIds)
            
            // Apply relationship rules
            try await createMetadataRelationships(nodeIds: nodeIds, result: result)
            
            // Create temporal relationships for activities and events
            if let activityIds = nodeIds[.activity] {
                try await createTemporalRelationships(
                    items: result.activities,
                    type: .activity,
                    nodeIds: activityIds
                )
            }
            
            // Create co-occurrence networks for keywords and topics
            if let keywordIds = nodeIds[.keyword] {
                try await createCoOccurrenceNetwork(
                    items: result.keywords,
                    type: .keyword,
                    nodeIds: keywordIds
                )
            }
            
            // Commit the transaction
            try await graph.commitTransaction()
            
        } catch {
            // Rollback in case of any errors
            await graph.rollbackTransaction()
            throw error
        }
    }
    
    // MARK: - Node Creation
    
    /// Creates nodes for different metadata types
    /// - Parameter result: Metadata result containing various node types
    /// - Returns: A dictionary mapping node types to their created node IDs
    private func createNodes(from result: MetaDataResult) async throws -> [NodeType: [UUID]] {
        var nodeIds: [NodeType: [UUID]] = [:]
        
        try await withThrowingTaskGroup(of: (NodeType, [UUID]).self) { group in
            // Process keywords
            group.addTask {
                let ids = try await result.keywords.asyncMap { keyword in
                    try await self.graph.addNode(
                        keyword.value,
                        type: .keyword,
                        metadata: [
                            "confidence": Double(keyword.confidenceScore),
                            "frequency": Double(keyword.frequency),
                            "isCompound": keyword.isCompound ? 1.0 : 0.0
                        ]
                    )
                }
                return (.keyword, ids)
            }
            
            // Process topics
            group.addTask {
                let ids = try await result.topics.asyncMap { topic in
                    try await self.graph.addNode(
                        topic.value,
                        type: .topic,
                        metadata: [
                            "confidence": Double(topic.confidenceScore),
                            "hierarchyLevel": Double(topic.hierarchyLevel)
                        ]
                    )
                }
                return (.topic, ids)
            }
            
            // Process other metadata types similarly
            // Emotions, locations, activities, persons, etc.
            // Each with appropriate metadata extraction
            
            // Collect results
            for try await (type, ids) in group {
                nodeIds[type] = ids
            }
        }
        
        return nodeIds
    }
    
    // MARK: - Relationship Creation Methods
    
    /// Connects metadata nodes to the original thought
    /// - Parameters:
    ///   - thoughtId: The unique identifier of the thought
    ///   - nodeIds: Dictionary of node types and their created node IDs
    private func connectMetadataToThought(
        thoughtId: UUID,
        nodeIds: [NodeType: [UUID]]
    ) async throws {
        try await nodeIds.values.asyncForEach { ids in
            try await ids.asyncForEach { nodeId in
                try await self.graph.connect(
                    sourceId: thoughtId,
                    targetId: nodeId,
                    type: .has,
                    weight: 1.0
                )
            }
        }
    }
    
    /// Creates relationships between metadata nodes based on predefined rules
    /// - Parameters:
    ///   - nodeIds: Dictionary of node types and their created node IDs
    ///   - result: The full metadata result
    private func createMetadataRelationships(
        nodeIds: [NodeType: [UUID]],
        result: MetaDataResult
    ) async throws {
        for rule in relationshipRules {
            guard let sourceIds = nodeIds[rule.sourceType],
                  let targetIds = nodeIds[rule.targetType] else {
                continue
            }
            
            let sourceItems = getMetadataItems(for: rule.sourceType, from: result)
            let targetItems = getMetadataItems(for: rule.targetType, from: result)
            
            for (sourceId, sourceItem) in zip(sourceIds, sourceItems) {
                for (targetId, targetItem) in zip(targetIds, targetItems) {
                    if rule.condition(sourceItem, targetItem) {
                        let weight = rule.weightModifier?(sourceItem, targetItem) ?? rule.baseWeight
                        try await graph.connect(
                            sourceId: sourceId,
                            targetId: targetId,
                            type: rule.relationType,
                            weight: weight
                        )
                    }
                }
            }
        }
    }
    
    /// Creates temporal relationships between items
    /// - Parameters:
    ///   - items: Metadata items to create temporal relationships for
    ///   - type: Node type of the items
    ///   - nodeIds: Corresponding node IDs
    private func createTemporalRelationships(
        items: [MetaData],
        type: NodeType,
        nodeIds: [UUID]
    ) async throws {
        let sortedItems = items.enumerated()
            .sorted { $0.element.sourcePosition?.lowerBound ?? 0 < $1.element.sourcePosition?.lowerBound ?? 0 }
        
        for i in 0..<(sortedItems.count - 1) {
            let current = sortedItems[i]
            let next = sortedItems[i + 1]
            
            // Only create temporal relationships if items are close enough
            guard let currentPos = current.element.sourcePosition,
                  let nextPos = next.element.sourcePosition,
                  nextPos.lowerBound - currentPos.upperBound < 200 else {
                continue
            }
            
            
            try await graph.connect(
                sourceId: nodeIds[current.offset],
                targetId: nodeIds[next.offset],
                type: .precedes,
                weight: (current.element.confidenceScore + next.element.confidenceScore) / 2
            )
        }
    }
    
    /// Creates a co-occurrence network for items
    /// - Parameters:
    ///   - items: Metadata items to create co-occurrence relationships for
    ///   - type: Node type of the items
    ///   - nodeIds: Corresponding node IDs
    private func createCoOccurrenceNetwork(
        items: [MetaData],
        type: NodeType,
        nodeIds: [UUID]
    ) async throws {
        let windowSize = 100 // characters
        
        for i in 0..<items.count {
            let item1 = items[i]
            guard let pos1 = item1.sourcePosition else { continue }
            
            for j in (i + 1)..<items.count {
                let item2 = items[j]
                guard let pos2 = item2.sourcePosition else { continue }
                
                if abs(pos1.lowerBound - pos2.lowerBound) < windowSize {
                    try await graph.connect(
                        sourceId: nodeIds[i],
                        targetId: nodeIds[j],
                        type: .coOccurs,
                        weight: Float(min(item1.frequency, item2.frequency)) /
                                Float(max(item1.frequency, item2.frequency))
                    )
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// Retrieves metadata items for a specific node type
    /// - Parameters:
    ///   - type: The node type to retrieve
    ///   - result: The full metadata result
    /// - Returns: An array of metadata items for the specified type
    private func getMetadataItems(for type: NodeType, from result: MetaDataResult) -> [MetaData] {
        switch type {
        case .keyword: return result.keywords
        case .topic: return result.topics
        case .emotion: return result.emotions
        case .location: return result.locations
        case .activity: return result.activities
        case .person: return result.persons
        default: return []
        }
    }
    
    // MARK: - Rule Management
    
    /// Adds a custom relationship rule to the builder
    /// - Parameters:
    ///   - sourceType: The source node type
    ///   - targetType: The target node type
    ///   - relationType: The type of relationship
    ///   - baseWeight: Default weight for the relationship
    ///   - condition: A closure to determine if a relationship should be created
    ///   - weightModifier: An optional closure to dynamically calculate relationship weight
    func addRelationshipRule(
        sourceType: NodeType,
        targetType: NodeType,
        relationType: MetadataRelationType,
        baseWeight: Float,
        condition: @escaping (MetaData, MetaData) -> Bool,
        weightModifier: ((MetaData, MetaData) -> Float)? = nil
    ) {
        let rule = RelationshipRule(
            sourceType: sourceType,
            targetType: targetType,
            relationType: relationType,
            baseWeight: baseWeight,
            condition: condition,
            weightModifier: weightModifier
        )
        relationshipRules.append(rule)
    }
}

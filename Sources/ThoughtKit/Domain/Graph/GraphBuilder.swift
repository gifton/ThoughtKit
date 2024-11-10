
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
final class GraphBuilder {
    private let graph: Graph
    
    enum Error: LocalizedError {
        case storeNotAvailable
    }
    
    private struct RelationshipRule {
        let sourceType: NodeType
        let targetType: NodeType
        let relationType: MetadataRelationType
        let baseWeight: Float
        let condition: (MetaData, MetaData) -> Bool
        let weightModifier: ((MetaData, MetaData) -> Float)?
    }
    
    // Default relationship rules based on metadata types and semantic relationships
    private var relationshipRules: [RelationshipRule] = [
        // Keywords <-> Keywords (Co-occurrence)
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
        
        // Topics Hierarchy
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
        
        // Keywords -> Topics (Part-of relationship)
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
        
        // Sequential Activities
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
        },
        
        // Emotion correlations
        RelationshipRule(
            sourceType: .emotion,
            targetType: .emotion,
            relationType: .correlates,
            baseWeight: 0.5
        ) { emotion1, emotion2 in
            guard let pos1 = emotion1.sourcePosition,
                  let pos2 = emotion2.sourcePosition else { return false }
            // Emotions correlate if they appear close together
            return abs(pos1.lowerBound - pos2.lowerBound) < 150
        } weightModifier: { emotion1, emotion2 in
            // Weight based on confidence and proximity
            (emotion1.confidenceScore + emotion2.confidenceScore) / 2
        },
        
        // Location hierarchies
        RelationshipRule(
            sourceType: .location,
            targetType: .location,
            relationType: .broader,
            baseWeight: 0.9
        ) { loc1, loc2 in
            guard let location1 = loc1 as? MDResult.Location,
                  let location2 = loc2 as? MDResult.Location else { return false }
            // Create location hierarchies based on location types
            return location1.locationType.isAdministrative &&
                   location2.locationType.isAdministrative &&
                   location1.precision < location2.precision
        } weightModifier: { loc1, loc2 in
            // Higher confidence for clear administrative hierarchies
            loc1.confidenceScore * loc2.confidenceScore
        }
    ]
    
    init(graph: Graph) {
        self.graph = graph
    }
    
    /// Creates relationships based on temporal proximity
    private func createTemporalRelationships(items: [MetaData], type: NodeType, nodeIds: [UUID]) async throws {
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
    
    /// Creates relationship networks based on proximity and frequency
    private func createCoOccurrenceNetwork(items: [MetaData], type: NodeType, nodeIds: [UUID]) async throws {
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
                        weight: Float(min(item1.frequency, item2.frequency)) / Float(max(item1.frequency, item2.frequency))
                    )
                }
            }
        }
    }
    
    private func createNodes(from result: MetaDataResult) async throws -> [NodeType: [UUID]] {
        var nodeIds: [NodeType: [UUID]] = [:]
        
        // Process each type of metadata
        try await withThrowingTaskGroup(of: (NodeType, [UUID]).self) { group in
            // Add keywords
            group.addTask {
                let ids = try await result.keywords.asyncMap { keyword in
                    try await self.graph.addNode(
                        keyword.value,
                        type: .keyword,
                        metadata: ["confidence": Double(keyword.confidenceScore)]
                    )
                }
                return (.keyword, ids)
            }
            
            // Add topics
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
            
            // Add all other types similarly...
            // (emotions, locations, activities, persons)
            
            // Collect results
            for try await (type, ids) in group {
                nodeIds[type] = ids
            }
        }
        
        return nodeIds
    }
    
    func processRelationships(thoughtId: UUID, result: MetaDataResult) async throws {
        // Create nodes for all metadata items
        let nodeIds = try await createNodes(from: result)
        
        // Connect metadata to thought
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
    }
    
    private func connectMetadataToThought(thoughtId: UUID, nodeIds: [NodeType: [UUID]]) async throws {
        try await nodeIds.values.asyncForEach { [weak self] ids in
            guard let self = self else { throw Error.storeNotAvailable }
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
    
    private func createMetadataRelationships(nodeIds: [NodeType: [UUID]], result: MetaDataResult) async throws {
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

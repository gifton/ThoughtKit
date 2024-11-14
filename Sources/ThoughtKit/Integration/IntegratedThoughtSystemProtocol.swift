//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation
/// Defines the primary interface for the integrated thought processing system
protocol IntegratedThoughtSystemProtocol: Actor {
    /// Process new content, creating necessary connections across all systems
    func processNode(id: UUID, type: NodeType, content: Any) async throws
    
    /// Find related nodes across all systems
    func findRelated(
        to nodeId: UUID,
        types: Set<NodeType>,
        relations: Set<MetadataRelationType>,
        context: QueryContext
    ) async throws -> [RelatedNode]
    
    /// Update existing node with new content or relationships
    func updateNode(id: UUID, newContent: Any) async throws
    
    /// Remove node and its relationships from all systems
    func removeNode(id: UUID) async throws
    
    /// Analyze patterns and generate insights across all systems
    func analyzePatterns() async throws -> [ThoughtPattern]
    
    /// Merge insights from all systems
    func mergeInsights() async throws -> [SystemInsight]
}

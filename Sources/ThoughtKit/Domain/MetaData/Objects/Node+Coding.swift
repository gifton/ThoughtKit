//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/21/24.
//

import Foundation
extension MetadataNode {
    enum CodingKeys: String, CodingKey {
        case id, type, value, connections, createdAt
        case incomingEdges, outgoingEdges, bidirectionalEdges
        case frequency, lastUsed, accessCount, strength
        case metadata, contextualMetadata, tags
        case validityPeriod, temporalContext, lastModified
        case semanticContext, embeddings
        case centrality, clusterCoefficient, communityID
        case confidence, validationStatus, qualityMetrics
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode basic properties
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(value, forKey: .value)
        try container.encode(connections, forKey: .connections)
        try container.encode(createdAt, forKey: .createdAt)
        
        // Encode relationship sets
        try container.encode(incomingEdges, forKey: .incomingEdges)
        try container.encode(outgoingEdges, forKey: .outgoingEdges)
        try container.encode(bidirectionalEdges, forKey: .bidirectionalEdges)
        
        // Encode statistics
        try container.encode(frequency, forKey: .frequency)
        try container.encode(lastUsed, forKey: .lastUsed)
        try container.encode(accessCount, forKey: .accessCount)
        try container.encode(strength, forKey: .strength)
        
        // Encode metadata
        try container.encode(metadata, forKey: .metadata)
        try container.encode(tags, forKey: .tags)
        
        // Encode temporal properties
        try container.encodeIfPresent(validityPeriod, forKey: .validityPeriod)
        try container.encodeIfPresent(temporalContext, forKey: .temporalContext)
        try container.encode(lastModified, forKey: .lastModified)
        
        // Encode semantic properties
        try container.encodeIfPresent(semanticContext, forKey: .semanticContext)
        try container.encodeIfPresent(embeddings, forKey: .embeddings)
        
        // Encode graph analysis properties
        try container.encode(centrality, forKey: .centrality)
        try container.encode(clusterCoefficient, forKey: .clusterCoefficient)
        try container.encodeIfPresent(communityID, forKey: .communityID)
        
        // Encode validation properties
        try container.encode(confidence, forKey: .confidence)
        try container.encode(validationStatus, forKey: .validationStatus)
        try container.encode(qualityMetrics, forKey: .qualityMetrics)
        
        try container.encode(contextualMetadata, forKey: .contextualMetadata)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode basic properties
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(NodeType.self, forKey: .type)
        value = try container.decode(String.self, forKey: .value)
        connections = try container.decode(Set<MetadataConnection>.self, forKey: .connections)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // Decode relationship sets
        incomingEdges = try container.decode(Set<UUID>.self, forKey: .incomingEdges)
        outgoingEdges = try container.decode(Set<UUID>.self, forKey: .outgoingEdges)
        bidirectionalEdges = try container.decode(Set<UUID>.self, forKey: .bidirectionalEdges)
        
        // Decode statistics
        frequency = try container.decode(Int.self, forKey: .frequency)
        lastUsed = try container.decode(Date.self, forKey: .lastUsed)
        accessCount = try container.decode(Int.self, forKey: .accessCount)
        strength = try container.decode(Float.self, forKey: .strength)
        
        // Decode metadata
        metadata = try container.decode(TypedMetadata.self, forKey: .metadata)
        tags = try container.decode(Set<String>.self, forKey: .tags)
        
        // Decode temporal properties
        validityPeriod = try container.decodeIfPresent(ClosedRange<Date>.self, forKey: .validityPeriod)
        temporalContext = try container.decode(TemporalContext.self, forKey: .temporalContext)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
        
        // Decode semantic properties
        semanticContext = try container.decodeIfPresent(SemanticContext.self, forKey: .semanticContext)
        embeddings = try container.decodeIfPresent([Float].self, forKey: .embeddings)
        
        // Decode graph analysis properties
        centrality = try container.decode(Float.self, forKey: .centrality)
        clusterCoefficient = try container.decode(Float.self, forKey: .clusterCoefficient)
        communityID = try container.decodeIfPresent(UUID.self, forKey: .communityID)
        
        // Decode validation properties
        confidence = try container.decode(Float.self, forKey: .confidence)
        validationStatus = try container.decode(ValidationStatus.self, forKey: .validationStatus)
        qualityMetrics = try container.decode(QualityMetrics.self, forKey: .qualityMetrics)
        
        // Handle contextualMetadata separately
        let encodedContextualMetadata = try container.decode([String: String].self, forKey: .contextualMetadata)
        contextualMetadata = try container.decode(ContextualMetadata.self, forKey: .contextualMetadata)
    }
}

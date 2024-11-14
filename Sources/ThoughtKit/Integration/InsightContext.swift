//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

struct InsightContext {
    // Temporal information
    var timestamp: Date
    var temporalRange: ClosedRange<Date>?
    
    // Context classification
    var source: InsightSource
    var confidence: Float
    var relevance: Float
    
    // Content context
    var relatedTypes: Set<NodeType>
    var relationTypes: Set<MetadataRelationType>
    var semanticContext: Set<String>
    
    // Pattern information
    var patternStrength: Float
    var patternFrequency: Int
    var patternStability: Float
    
    // Analysis metadata
    var analysisMethod: String
    var analysisTimestamp: Date
    var validityPeriod: TimeInterval?
    
    // Additional context
    var metadata: [String: Any]
    var tags: Set<String>
    
    struct ValidationContext {
        var isVerified: Bool
        var verificationMethod: String?
        var lastVerified: Date?
        var verificationConfidence: Float
    }
    var validation: ValidationContext?
}

// Supporting types if needed
extension InsightContext {
    enum AnalysisMethod: String {
        case neuralPattern = "neural_pattern"
        case graphAnalysis = "graph_analysis"
        case hypergraphCluster = "hypergraph_cluster"
        case temporalAnalysis = "temporal_analysis"
        case semanticAnalysis = "semantic_analysis"
        case hybridAnalysis = "hybrid_analysis"
    }
}

//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

struct ClusterContext {
   // Core cluster properties
   let id: UUID
   var createdAt: Date
   var lastUpdated: Date
   
   // Cluster characteristics
   var size: Int
   var density: Float
   var cohesion: Float
   
   // Temporal aspects
   var temporalRange: ClosedRange<Date>?
   var activeTime: TimeInterval
   var lastActivity: Date
   
   // Semantic properties
   var dominantConcepts: [String: Float]  // Concept -> Weight
   var sharedAttributes: Set<String>
   var semanticCohesion: Float
   
   // Relationship characteristics
   var internalConnections: Int
   var externalConnections: Int
   var connectionTypes: [MetadataRelationType: Int]
   
   // Cluster dynamics
   var growth: ClusterGrowth
   var stability: ClusterStability
   var evolution: ClusterEvolution
   
   // Analysis metadata
   var analysisContext: AnalysisContext
   var quality: QualityMetrics
   var validation: ValidationInfo
   
   struct ClusterGrowth {
       var growthRate: Float
       var expansionHistory: [ExpansionRecord]
       var predictedGrowth: Float?
       
       struct ExpansionRecord {
           let timestamp: Date
           let sizeChange: Int
           let trigger: ExpansionTrigger
       }
       
       enum ExpansionTrigger {
           case newNode
           case mergeClusters
           case patternMatch
           case userAction
           case systemOptimization
       }
   }
   
   struct ClusterStability {
       var stabilityScore: Float
       var membershipChanges: [MembershipChange]
       var structuralIntegrity: Float
       
       struct MembershipChange {
           let timestamp: Date
           let nodeID: UUID
           let changeType: ChangeType
           let impact: Float
       }
       
       enum ChangeType {
           case addition
           case removal
           case merger
           case split
       }
   }
   
   struct ClusterEvolution {
       var stage: EvolutionStage
       var transitions: [EvolutionTransition]
       var predictions: [EvolutionPrediction]
       
       enum EvolutionStage {
           case forming
           case stabilizing
           case mature
           case declining
           case splitting
       }
       
       struct EvolutionTransition {
           let fromStage: EvolutionStage
           let toStage: EvolutionStage
           let timestamp: Date
           let trigger: String
       }
       
       struct EvolutionPrediction {
           let predictedStage: EvolutionStage
           let confidence: Float
           let timeframe: TimeInterval
       }
   }
   
   struct AnalysisContext {
       var method: AnalysisMethod
       var parameters: TypedMetadata
       var timestamp: Date
       var duration: TimeInterval
       
       enum AnalysisMethod {
           case densityBased
           case hierarchical
           case semantic
           case temporal
           case hybrid
       }
   }
   
   struct QualityMetrics {
       var silhouetteScore: Float
       var dbIndex: Float
       var dunnIndex: Float
       var intraClusterDistance: Float
       var interClusterDistance: Float
   }
   
   struct ValidationInfo {
       var isValid: Bool
       var validationMethod: String
       var lastValidated: Date
       var validationScore: Float
       var issues: [ValidationIssue]
       
       struct ValidationIssue {
           let type: IssueType
           let severity: Float
           let description: String
       }
       
       enum IssueType {
           case coherence
           case stability
           case isolation
           case density
           case quality
       }
   }
   
   // MARK: - Methods
   
   mutating func updateMetrics() {
       // Update cluster metrics based on current state
       updateDensity()
       updateCohesion()
       updateStability()
   }
   
   private mutating func updateDensity() {
       if internalConnections > 0 && size > 1 {
           let maxPossibleConnections = (size * (size - 1)) / 2
           density = Float(internalConnections) / Float(maxPossibleConnections)
       } else {
           density = 0
       }
   }
   
   private mutating func updateCohesion() {
       // Update semantic cohesion based on shared attributes
       semanticCohesion = Float(sharedAttributes.count) / Float(dominantConcepts.count)
   }
   
   private mutating func updateStability() {
       // Calculate stability based on recent changes
       let recentChanges = stability.membershipChanges.filter {
           $0.timestamp > Date().addingTimeInterval(-86400) // Last 24 hours
       }
       
       stability.stabilityScore = 1.0 - (Float(recentChanges.count) / Float(size))
   }
   
   func shouldMerge(with other: ClusterContext) -> Bool {
       // Determine if clusters should be merged based on similarity
       let conceptOverlap = Set(dominantConcepts.keys)
           .intersection(Set(other.dominantConcepts.keys))
       let overlapRatio = Float(conceptOverlap.count) / Float(dominantConcepts.count)
       
       return overlapRatio > 0.7 && stability.stabilityScore > 0.8
   }
}

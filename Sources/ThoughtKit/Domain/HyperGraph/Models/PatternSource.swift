//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

enum PatternSource {
   // Core pattern origins
   case userGenerated(metadata: UserMetadata)
   case systemInferred(confidence: Float)
   case neuralNetwork(activation: Float)
   case graphAnalysis(strength: Float)
   case hypergraphCluster(clusterID: UUID)
   case hybrid(sources: [PatternSource], weight: Float)
   
   struct UserMetadata {
       let userID: String
       let timestamp: Date
       var context: String?
       var confidence: Float
   }
   
   // Get confidence level for the source
   var confidence: Float {
       switch self {
       case .userGenerated(let metadata):
           return metadata.confidence
       case .systemInferred(let confidence):
           return confidence
       case .neuralNetwork(let activation):
           return activation
       case .graphAnalysis(let strength):
           return strength
       case .hypergraphCluster:
           return 1.0
       case .hybrid(let sources, let weight):
           // Average confidence weighted by the hybrid weight
           let avgConfidence = sources.reduce(0) { $0 + $1.confidence }
           return (avgConfidence / Float(sources.count)) * weight
       }
   }
}

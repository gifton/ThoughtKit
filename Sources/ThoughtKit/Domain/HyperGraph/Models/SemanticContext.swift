//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

struct SemanticContext {
    // Core semantic properties
    var concepts: Set<String>
    var categories: Set<String>
    var keywords: Set<String>
    
    // Semantic relationships
    var synonyms: Set<String>
    var antonyms: Set<String>
    var broaderTerms: Set<String>
    var narrowerTerms: Set<String>
    
    // Language and meaning
    var language: String
    var sentiment: SentimentInfo
    var intensity: Float  // 0.0 to 1.0
    var abstractionLevel: AbstractionLevel
    
    // Context confidence
    var confidence: Float
    var ambiguityScore: Float
    
    // Domain-specific context
    var domain: String?
    var subDomain: String?
    var contextualTags: Set<String>
    
    struct SentimentInfo {
        var value: Float      // -1.0 to 1.0
        var magnitude: Float  // 0.0 to 1.0
        var aspects: [String: Float]  // Aspect-based sentiment
    }
    
    enum AbstractionLevel {
        case concrete       // Tangible, specific concepts
        case intermediate  // Mix of specific and abstract
        case abstract      // Theoretical, conceptual
        case meta         // About other concepts
        
        var numericalValue: Float {
            switch self {
            case .concrete: return 0.0
            case .intermediate: return 0.33
            case .abstract: return 0.66
            case .meta: return 1.0
            }
        }
    }
    
    // Additional metadata
    var metadata: [String: Any]
    var lastUpdated: Date
    var sourceContext: SourceInfo
    
    struct SourceInfo {
        var origin: String
        var reliability: Float
        var verificationStatus: VerificationStatus
        
        enum VerificationStatus {
            case verified
            case unverified
            case inProgress
            case disputed
        }
    }
}

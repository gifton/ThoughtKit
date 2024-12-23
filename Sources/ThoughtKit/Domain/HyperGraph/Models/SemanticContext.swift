//
//  File.swift
//
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

struct SemanticContext: Hashable, Codable {
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
    
    // MARK: - Nested Types
    struct SentimentInfo: Hashable, Codable {
        var value: Float      // -1.0 to 1.0
        var magnitude: Float  // 0.0 to 1.0
        var aspects: [String: Float]  // Aspect-based sentiment
        
        // MARK: - Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(value)
            hasher.combine(magnitude)
            // Sort dictionary keys for consistent hashing
            let sortedAspects = aspects.sorted { $0.key < $1.key }
            for (key, value) in sortedAspects {
                hasher.combine(key)
                hasher.combine(value)
            }
        }
        
        static func == (lhs: SentimentInfo, rhs: SentimentInfo) -> Bool {
            lhs.value == rhs.value &&
            lhs.magnitude == rhs.magnitude &&
            lhs.aspects == rhs.aspects
        }
    }
    
    enum AbstractionLevel: Hashable, Codable {
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
    var metadata: TypedMetadata
    var lastUpdated: Date
    var sourceContext: SourceInfo
    
    struct SourceInfo: Hashable, Codable {
        var origin: String
        var reliability: Float
        var verificationStatus: VerificationStatus
        
        // MARK: - Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(origin)
            hasher.combine(reliability)
            hasher.combine(verificationStatus)
        }
        
        enum VerificationStatus: String, Codable, Hashable {
            case verified
            case unverified
            case inProgress
            case disputed
        }
    }
    
    // MARK: - Hashable Implementation
    func hash(into hasher: inout Hasher) {
        // Hash core semantic properties
        hasher.combine(concepts)
        hasher.combine(categories)
        hasher.combine(keywords)
        
        // Hash semantic relationships
        hasher.combine(synonyms)
        hasher.combine(antonyms)
        hasher.combine(broaderTerms)
        hasher.combine(narrowerTerms)
        
        // Hash language and meaning
        hasher.combine(language)
        hasher.combine(sentiment)
        hasher.combine(intensity)
        hasher.combine(abstractionLevel)
        
        // Hash context confidence
        hasher.combine(confidence)
        hasher.combine(ambiguityScore)
        
        // Hash domain-specific context
        hasher.combine(domain)
        hasher.combine(subDomain)
        hasher.combine(contextualTags)
        
        // Hash metadata (excluding Dictionary<String, Any> as it's not Hashable)
        hasher.combine(lastUpdated)
        hasher.combine(sourceContext)
        hasher.combine(metadata)
        
    }
    
    static func == (lhs: SemanticContext, rhs: SemanticContext) -> Bool {
        // Compare core semantic properties
        guard lhs.concepts == rhs.concepts,
              lhs.categories == rhs.categories,
              lhs.keywords == rhs.keywords,
              
              // Compare semantic relationships
              lhs.synonyms == rhs.synonyms,
              lhs.antonyms == rhs.antonyms,
              lhs.broaderTerms == rhs.broaderTerms,
              lhs.narrowerTerms == rhs.narrowerTerms,
              
              // Compare language and meaning
              lhs.language == rhs.language,
              lhs.sentiment == rhs.sentiment,
              lhs.intensity == rhs.intensity,
              lhs.abstractionLevel == rhs.abstractionLevel,
              
              // Compare context confidence
              lhs.confidence == rhs.confidence,
              lhs.ambiguityScore == rhs.ambiguityScore,
              
              // Compare domain-specific context
              lhs.domain == rhs.domain,
              lhs.subDomain == rhs.subDomain,
              lhs.contextualTags == rhs.contextualTags,
              
              // Compare metadata timestamps and source
              lhs.lastUpdated == rhs.lastUpdated,
              lhs.sourceContext == rhs.sourceContext else {
            return false
        }
        
        // Compare metadata keys (since values aren't guaranteed to be Equatable)
        return lhs.metadata == rhs.metadata
    }
    
    // MARK: - Convenience Methods for Metadata Handling
    
    /// Updates metadata while maintaining type safety
    mutating func updateMetadata(key: String, value: Any) {
        metadata[key] = value
    }
    
    /// Retrieves metadata value with type casting
    func getMetadata<T>(key: String) -> T? {
        return metadata[key] as? T
    }
    
    // Removes metadata for a specific key
    /// Returns the removed value if it existed, nil otherwise
    @discardableResult
    mutating func removeMD<T>(for key: String, type: T.Type) -> T? {
        guard !self.metadata.isEmpty,
                let removedValue = metadata[key] as? T else {
            return nil
        }
        
        
        metadata.remove(key, type: type)
        
        // If metadata is now empty, set it to nil
        self.metadata = metadata.isEmpty ? .init() : metadata
        
        // Update lastUpdated timestamp
        self.lastUpdated = Date()
        
        return removedValue
    }
    
    /// Removes multiple metadata keys at once
    /// Returns a dictionary of the removed key-value pairs
    @discardableResult
    mutating func removeMetadata<T>(keys: [String], type: T.Type) -> [String: Any] {
        var removedValues: [String: Any] = [:]
        
        for key in keys {
            if let removed = removeMD(for: key, type: type){
                removedValues[key] = removed
            }
        }
        
        return removedValues
    }
}

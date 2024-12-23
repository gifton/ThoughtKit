//
//  File.swift
//
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

public struct ConnectionMetadata: Hashable, Codable {
    public init(
        id: UUID = .init(),
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        version: Int = 1,
        weight: Float = 0,
        confidence: Float = 0,
        stability: Float = 1,
        activationCount: Int = 0,
        lastAccessed: Date? = Date(),
        accessFrequency: Float = 0,
        activationHistory: [ConnectionMetadata.ActivationRecord] = [],
        connectionType: ConnectionMetadata.ConnectionType = .direct,
        bidirectional: Bool = false,
        inheritanceRules: Set<ConnectionMetadata.InheritanceRule>? = nil,
        context: ConnectionMetadata.ConnectionContext = .init(source: .inference, relevance: 1),
        validationState: ConnectionMetadata.ValidationState = .init(isValid: true),
        customProperties: TypedMetadata = .init(),
        tags: Set<String>) {
            self.id = id
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.version = version
            self.weight = weight
            self.confidence = confidence
            self.stability = stability
            self.activationCount = activationCount
            self.lastAccessed = lastAccessed
            self.accessFrequency = accessFrequency
            self.activationHistory = activationHistory
            self.connectionType = connectionType
            self.bidirectional = bidirectional
            self.inheritanceRules = inheritanceRules
            self.context = context
            self.validationState = validationState
            self.customProperties = customProperties
            self.tags = tags
        }
    
   // Core metadata
   let id: UUID
   var createdAt: Date
   var updatedAt: Date
   var version: Int
   
   // Connection strength characteristics
   var weight: Float               // Base connection weight (0.0 to 1.0)
   var confidence: Float           // Confidence in the connection (0.0 to 1.0)
   var stability: Float            // How stable/reliable the connection is (0.0 to 1.0)
   var activationCount: Int        // Number of times this connection has been activated
   
   // Usage patterns
   var lastAccessed: Date?
   var accessFrequency: Float      // Average accesses per time period
   var activationHistory: [ActivationRecord]
   
   // Connection type information
   var connectionType: ConnectionType
   var bidirectional: Bool
   var inheritanceRules: Set<InheritanceRule>?
   
   // Context and validation
   var context: ConnectionContext
   var validationState: ValidationState
   
   // Custom properties
   var customProperties: TypedMetadata
   var tags: Set<String>
    
    
   
    public struct ActivationRecord: Hashable, Codable {
       let timestamp: Date
       var strength: Float
       var context: String?
       var duration: TimeInterval?
       
       // MARK: - Hashable
        public func hash(into hasher: inout Hasher) {
           hasher.combine(timestamp)
           hasher.combine(strength)
           hasher.combine(context)
           hasher.combine(duration)
       }
   }
   
    public enum ConnectionType: Hashable, Codable {
       case direct         // Explicit connection
       case derived       // Inferred/calculated connection
       case temporary     // Short-term connection
       case composite     // Combined from multiple sources
       case learned      // Learned through pattern recognition
   }
   
    public enum InheritanceRule: Hashable, Codable {
       case properties    // Inherit properties
       case relations    // Inherit relationships
       case context     // Inherit context
       case custom(String) // Custom inheritance rule
   }
   
    public struct ConnectionContext: Hashable, Codable {
        
        public init(source: ConnectionSource = .inference, relevance: Float = 1, domain: String? = nil, purpose: String? = nil) {
            self.source = source
            self.relevance = relevance
            self.domain = domain
            self.purpose = purpose
        }
        
       var source: ConnectionSource
       var relevance: Float
       var domain: String?
       var purpose: String?
       
       public enum ConnectionSource: Hashable, Codable {
           case user
           case system
           case inference
           case external(source: String)
       }
       
       // MARK: - Hashable
        public func hash(into hasher: inout Hasher) {
           hasher.combine(source)
           hasher.combine(relevance)
           hasher.combine(domain)
           hasher.combine(purpose)
       }
   }
   
    public struct ValidationState: Hashable, Codable {
        
        public init(isValid: Bool, lastValidated: Date? = nil, validationMethod: String? = nil, validationScore: Float? = nil, invalidationReason: String? = nil) {
            self.isValid = isValid
            self.lastValidated = lastValidated
            self.validationMethod = validationMethod
            self.validationScore = validationScore
            self.invalidationReason = invalidationReason
        }
        
       var isValid: Bool
       var lastValidated: Date?
       var validationMethod: String?
       var validationScore: Float?
       var invalidationReason: String?
       
       // Validation lifecycle
       func validate() -> Bool {
           // Implement validation logic
           return true
       }
       
       mutating func invalidate(reason: String) {
           isValid = false
           invalidationReason = reason
       }
       
       // MARK: - Hashable
        public func hash(into hasher: inout Hasher) {
           hasher.combine(isValid)
           hasher.combine(lastValidated)
           hasher.combine(validationMethod)
           hasher.combine(validationScore)
           hasher.combine(invalidationReason)
       }
   }
}

// MARK: - Hashable Conformance
extension ConnectionMetadata {
    
    // TODO: create decoder initializer
    public init(from decoder: any Decoder) throws {
        self.init(id: .init(), createdAt: .init(), updatedAt: .init(), version: 1, weight: 0, confidence: 0, stability: 0, activationCount: 0, accessFrequency: 0, activationHistory: [], connectionType: .direct, bidirectional: false, context: .init(source: .inference, relevance: 0), validationState: .init(isValid: true), customProperties: .init(), tags: [])
    }
    public func hash(into hasher: inout Hasher) {
        // Hash core properties
        hasher.combine(id)
        hasher.combine(createdAt)
        hasher.combine(updatedAt)
        hasher.combine(version)
        
        // Hash connection characteristics
        hasher.combine(weight)
        hasher.combine(confidence)
        hasher.combine(stability)
        hasher.combine(activationCount)
        
        // Hash usage patterns
        hasher.combine(lastAccessed)
        hasher.combine(accessFrequency)
        hasher.combine(activationHistory)
        
        // Hash type information
        hasher.combine(connectionType)
        hasher.combine(bidirectional)
        hasher.combine(inheritanceRules)
        
        // Hash context and validation
        hasher.combine(context)
        hasher.combine(validationState)
        
        // Hash tags
        hasher.combine(tags)
        
        // Note: customProperties is not included in hash calculation
        // because Dictionary<String, Any> is not Hashable
    }
    
    public static func == (lhs: ConnectionMetadata, rhs: ConnectionMetadata) -> Bool {
        // Compare core properties
        guard lhs.id == rhs.id,
              lhs.createdAt == rhs.createdAt,
              lhs.updatedAt == rhs.updatedAt,
              lhs.version == rhs.version,
              
              // Compare connection characteristics
              lhs.weight == rhs.weight,
              lhs.confidence == rhs.confidence,
              lhs.stability == rhs.stability,
              lhs.activationCount == rhs.activationCount,
              
              // Compare usage patterns
              lhs.lastAccessed == rhs.lastAccessed,
              lhs.accessFrequency == rhs.accessFrequency,
              lhs.activationHistory == rhs.activationHistory,
              
              // Compare type information
              lhs.connectionType == rhs.connectionType,
              lhs.bidirectional == rhs.bidirectional,
              lhs.inheritanceRules == rhs.inheritanceRules,
              
              // Compare context and validation
              lhs.context == rhs.context,
              lhs.validationState == rhs.validationState,
              
              // Compare tags
              lhs.tags == rhs.tags else {
            return false
        }
        
        // Compare custom properties keys
        // Note: We only compare keys since values aren't guaranteed to be Equatable
        return lhs.customProperties == rhs.customProperties
    }
}

// MARK: - Extensions

extension ConnectionMetadata {
   enum CodingKeys: String, CodingKey {
       case id, createdAt, updatedAt, version
       case weight, confidence, stability, activationCount
       case lastAccessed, accessFrequency, activationHistory
       case connectionType, bidirectional, inheritanceRules
       case context, validationState
       case tags
       // Note: customProperties would need special handling for Codable
   }
}

// MARK: - Factory Methods

extension ConnectionMetadata {
   static func create(
       type: ConnectionType,
       weight: Float,
       source: ConnectionContext.ConnectionSource
   ) -> ConnectionMetadata {
       ConnectionMetadata(
        id: UUID(),
        createdAt: Date(),
        updatedAt: Date(),
        version: 1,
        weight: weight,
        confidence: 1.0,
        stability: 1.0,
        activationCount: 0,
        accessFrequency: 0.0,
        activationHistory: [],
        connectionType: type,
        bidirectional: false,
        context: ConnectionContext(
            source: source,
            relevance: 1.0
        ),
        validationState: ValidationState(isValid: true),
        customProperties: .init(),
        tags: []
       )
   }
}

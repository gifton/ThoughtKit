//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

struct ConnectionMetadata {
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
   var customProperties: [String: Any]
   var tags: Set<String>
   
   struct ActivationRecord {
       let timestamp: Date
       var strength: Float
       var context: String?
       var duration: TimeInterval?
   }
   
   enum ConnectionType: Hashable {
       case direct         // Explicit connection
       case derived       // Inferred/calculated connection
       case temporary     // Short-term connection
       case composite     // Combined from multiple sources
       case learned      // Learned through pattern recognition
   }
   
    enum InheritanceRule: Hashable {
       case properties    // Inherit properties
       case relations    // Inherit relationships
       case context     // Inherit context
       case custom(String) // Custom inheritance rule
   }
   
   struct ConnectionContext: Hashable {
       var source: ConnectionSource
       var relevance: Float
       var domain: String?
       var purpose: String?
       
       enum ConnectionSource: Hashable {
           case user
           case system
           case inference
           case external(source: String)
       }
   }
   
   struct ValidationState: Hashable {
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
   }
   
   // MARK: - Lifecycle Methods
   
   mutating func updateAccess() {
       lastAccessed = Date()
       activationCount += 1
       
       // Record activation
       activationHistory.append(ActivationRecord(
           timestamp: Date(),
           strength: weight
       ))
       
       // Update frequency
       updateAccessFrequency()
   }
   
   private mutating func updateAccessFrequency() {
       // Calculate average frequency based on history
       guard let firstAccess = activationHistory.first?.timestamp else { return }
       
       let totalTime = Date().timeIntervalSince(firstAccess)
       accessFrequency = Float(activationCount) / Float(totalTime)
   }
   
   // MARK: - Utility Methods
   
   func isActive(within timeFrame: TimeInterval) -> Bool {
       guard let lastAccess = lastAccessed else { return false }
       return Date().timeIntervalSince(lastAccess) <= timeFrame
   }
   
   func getStrength(at date: Date) -> Float {
       // Calculate strength based on history
       guard let record = activationHistory.last(where: { $0.timestamp <= date }) else {
           return 0.0
       }
       return record.strength
   }
   
   mutating func decay(rate: Float) {
       // Apply decay to connection weight
       let timeSinceLastAccess = lastAccessed.map { Date().timeIntervalSince($0) } ?? 0
       let decayFactor = 1.0 - (Float(timeSinceLastAccess) * rate)
       weight *= max(0, decayFactor)
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

extension ConnectionMetadata: Equatable {
   static func == (lhs: ConnectionMetadata, rhs: ConnectionMetadata) -> Bool {
       lhs.id == rhs.id && lhs.version == rhs.version
   }
}

// MARK: - Factory Methods

extension ConnectionMetadata {
   static func create(
       type: ConnectionType,
       weight: Float,
       source: ConnectionContext.ConnectionSource
   ) -> ConnectionMetadata {
       ConnectionMetadata.init(
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
        customProperties: [:],
        tags: []
       )
   }
}

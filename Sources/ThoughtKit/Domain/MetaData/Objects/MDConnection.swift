//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/3/24.
//

import Foundation


/// Defines the structure for connections between nodes in the metadata network.
/// Connections are the edges in our graph structure and represent relationships
/// between nodes (e.g., a thought "has" a keyword, or two thoughts are "related").
/// Each connection has a direction (source → target) and a weight to represent
/// the strength of the relationship.
// MARK: - Enhanced MetadataConnection Protocol
public protocol EnhancedConnection {
    var id: UUID { get }
    var sourceId: UUID { get }
    var targetId: UUID { get }
    var type: MDRelationType { get }
    var weight: Float { get }
    
    var metadata: ConnectionMetadata { get set }
    var context: EdgeContext { get set }
    var validationState: MetadataConnection.ValidationState { get set }
    var lastValidated: Date { get set }
}

/// Concrete implementation of a Connection that represents relationships between nodes.
/// This structure maintains information about a single edge in the network,
/// including its strength and usage patterns over time.
// MARK: - MetadataConnection Implementation
public struct MetadataConnection: EnhancedConnection, Codable, Hashable, Identifiable {
    // MARK: - Core Properties
    public var id: UUID
    public var sourceId: UUID
    public var targetId: UUID
    public var type: MDRelationType
    public var weight: Float
    let createdAt: Date
    var lastAccessed: Date
    var occurrences: Int
    
    // MARK: - Enhanced Properties
    public var metadata: ConnectionMetadata
    public var context: EdgeContext
    public var validationState: ValidationState
    public var lastValidated: Date
    
    // MARK: - Performance Optimization
    private var _cachedHash: Int?
    private var _cachedDescription: String?
    
    // MARK: - Initialization
    public init(
        id: UUID = UUID(),
        sourceId: UUID,
        targetId: UUID,
        type: MDRelationType,
        weight: Float,
        metadata: ConnectionMetadata? = nil,
        context: EdgeContext? = nil
    ) {
        self.id = id
        self.sourceId = sourceId
        self.targetId = targetId
        self.type = type
        self.weight = weight
        self.createdAt = Date()
        self.lastAccessed = Date()
        self.occurrences = 1
        
        // Initialize with default or provided metadata
        self.metadata = metadata ?? ConnectionMetadata(
            id: id,
            createdAt: Date(),
            updatedAt: Date(),
            version: 1,
            weight: weight,
            confidence: 1.0,
            stability: 1.0,
            activationCount: 0,
            accessFrequency: 0.0,
            activationHistory: [],
            connectionType: .direct,
            bidirectional: type.isBidirectional,
            context: .init(source: .system, relevance: 1.0),
            validationState: .init(isValid: true),
            customProperties: .init(),
            tags: []
        )
        
        // Initialize with default or provided context
        self.context = context ?? EdgeContext(
            temporal: nil,
            semantic: nil,
            confidence: 1.0,
            metadata: .init()
        )
        
        self.validationState = ValidationState(isValid: true)
        self.lastValidated = Date()
    }
    
    // MARK: - Validation
    public struct ValidationState: Hashable, Codable, Equatable {
        var isValid: Bool
        var lastChecked: Date
        var validationMethod: String?
        var errors: [ValidationError]
        
        enum ValidationError: String, Codable {
            case invalidWeight
            case invalidType
            case brokenReference
            case outdatedMetadata
            case inconsistentState
        }
        
        init(isValid: Bool) {
            self.isValid = isValid
            self.lastChecked = Date()
            self.errors = []
        }
    }
    
    // MARK: - Connection Management
    mutating func recordAccess() {
        lastAccessed = Date()
        occurrences += 1
        metadata.activationCount += 1
        
        // Update activation history
        metadata.activationHistory.append(
            .init(timestamp: Date(), strength: weight)
        )
        
        // Maintain reasonable history size
        if metadata.activationHistory.count > 100 {
            metadata.activationHistory.removeFirst()
        }
        
        // Update access frequency
        updateAccessFrequency()
    }
    
    private mutating func updateAccessFrequency() {
        let timeInterval = Date().timeIntervalSince(createdAt)
        metadata.accessFrequency = Float(occurrences) / Float(timeInterval / 86400) // Daily frequency
    }
    
    // MARK: - Validation
    mutating func validate() -> Bool {
        var errors: [ValidationState.ValidationError] = []
        
        // Validate weight
        if weight < 0 || weight > 1 {
            errors.append(.invalidWeight)
        }
        
        // Validate type consistency
        if type.isBidirectional != metadata.bidirectional {
            errors.append(.inconsistentState)
        }
        
        // Check metadata freshness
        let staleThreshold: TimeInterval = 30 * 86400 // 30 days
        if Date().timeIntervalSince(metadata.updatedAt) > staleThreshold {
            errors.append(.outdatedMetadata)
        }
        
        validationState = .init(isValid: errors.isEmpty)
        validationState.errors = errors
        validationState.lastChecked = Date()
        
        lastValidated = Date()
        return validationState.isValid
    }
    
    // MARK: - Performance Optimizations
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: MetadataConnection, rhs: MetadataConnection) -> Bool {
        lhs.id == rhs.id
    }
    
    // Custom string conversion
    var description: String {
        """
        Connection(id: \(id), source: \(sourceId), target: \(targetId), \
        type: \(type), weight: \(weight), occurrences: \(occurrences))
        """
    }
    
    private mutating func setCacheDescription(_ string: String) {
        self._cachedDescription = string
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, sourceId, targetId, type, weight
        case createdAt, lastAccessed, occurrences
        case metadata, context, validationState, lastValidated
    }

    // MARK: - Connection Analysis Extensions

    // Calculate connection strength based on multiple factors
    var effectiveStrength: Float {
        let weightFactor = weight
        let frequencyFactor = min(Float(occurrences) / 100.0, 1.0)
        let recencyFactor = calculateRecencyFactor()
        let confidenceFactor = metadata.confidence
        
        return (weightFactor * 0.4 +
                frequencyFactor * 0.2 +
                recencyFactor * 0.2 +
                confidenceFactor * 0.2)
    }
    
    private func calculateRecencyFactor() -> Float {
        let daysSinceLastAccess = Date().timeIntervalSince(lastAccessed) / 86400
        return Float(exp(-daysSinceLastAccess / 30.0)) // Exponential decay over 30 days
    }
    
    // Get stability score based on history
    var stabilityScore: Float {
        guard !metadata.activationHistory.isEmpty else { return 0.0 }
        
        let weights = metadata.activationHistory.map { $0.strength }
        let mean = weights.reduce(0, +) / Float(weights.count)
        let variance = weights.map { pow($0 - mean, 2) }.reduce(0, +) / Float(weights.count)
        
        return 1.0 - min(sqrt(variance), 1.0) // Higher stability = lower variance
    }

    // MARK: - Async Extension for Heavy Operations
    // Perform expensive validation asynchronously
    mutating func validateAsync() async -> Bool {
        // Simulate complex validation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        return validate()
    }
    
    // Async metadata update
    mutating func updateMetadataAsync() async {
        var updatedMetadata = self.metadata
        
        // Simulate complex metadata update
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        updatedMetadata.updatedAt = Date()
        self.metadata = updatedMetadata
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(sourceId, forKey: .sourceId)
        try container.encode(targetId, forKey: .targetId)
        try container.encode(type, forKey: .type)
        try container.encode(weight, forKey: .weight)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastAccessed, forKey: .lastAccessed)
        try container.encode(occurrences, forKey: .occurrences)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(context, forKey: .context)
        try container.encode(validationState, forKey: .validationState)
        try container.encode(lastValidated, forKey: .lastValidated)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        sourceId = try container.decode(UUID.self, forKey: .sourceId)
        targetId = try container.decode(UUID.self, forKey: .targetId)
        type = try container.decode(MDRelationType.self, forKey: .type)
        weight = try container.decode(Float.self, forKey: .weight)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastAccessed = try container.decode(Date.self, forKey: .lastAccessed)
        occurrences = try container.decode(Int.self, forKey: .occurrences)
        metadata = try container.decode(ConnectionMetadata.self, forKey: .metadata)
        context = try container.decode(EdgeContext.self, forKey: .context)
        validationState = try container.decode(ValidationState.self, forKey: .validationState)
        lastValidated = try container.decode(Date.self, forKey: .lastValidated)
        
        _cachedDescription = nil
    }
}

//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/24/24.
//

import Foundation

//
//  QueryPattern.swift
//


/// Represents a pattern to match against in graph queries
struct QueryPattern: Hashable, Codable {
    // MARK: - Core Properties
    
    /// Unique identifier for the pattern
    let id: UUID
    
    /// Node patterns to match
    var nodePatterns: [NodePattern]
    
    /// Connection patterns to match
    var connectionPatterns: [ConnectionPattern]
    
    /// Optional temporal constraints for pattern matching
    var temporalConstraints: TemporalConstraints?
    
    /// Optional semantic constraints for pattern matching
    var semanticConstraints: SemanticConstraints?
    
    /// Minimum confidence required for matches (0.0 to 1.0)
    var minimumConfidence: Float
    
    // MARK: - Nested Types
    
    /// Defines a pattern for matching nodes
    struct NodePattern: Hashable, Codable {
        /// Optional specific node ID to match
        var nodeId: UUID?
        
        /// Required node type
        var nodeType: NodeType
        
        /// Optional value pattern to match (supports regex)
        var valuePattern: String?
        
        /// Required metadata keys and their patterns
        var metadataConstraints: [String: MetadataConstraint]
        
        /// Minimum required node strength
        var minimumStrength: Float?
        
        /// Optional temporal context requirements
        var temporalContext: TemporalContext?
        
        /// Optional semantic context requirements
        var semanticContext: SemanticContext?
    }
    
    /// Defines a pattern for matching connections
    struct ConnectionPattern: Hashable, Codable {
        /// Required connection type
        var relationType: MetadataRelationType
        
        /// Source node pattern index
        var sourcePatternIndex: Int
        
        /// Target node pattern index
        var targetPatternIndex: Int
        
        /// Minimum required weight
        var minimumWeight: Float?
        
        /// Required metadata keys and their patterns
        var metadataConstraints: [String: MetadataConstraint]
        
        /// Whether the connection can be indirect (through multiple hops)
        var allowIndirect: Bool
        
        /// Maximum number of hops if indirect connections are allowed
        var maxHops: Int?
    }
    
    /// Represents a constraint on metadata values
    enum MetadataConstraint: Hashable, Codable {
        /// Exact value match
        case equals(TypedMetadata)
        
        /// Range of values (for comparable types)
        case range(min: TypedMetadata, max: TypedMetadata)
        
        /// Set of allowed values
        case oneOf([TypedMetadata])
        
        /// Pattern match (for strings)
        case matches(String)
        
        /// Custom predicate represented as a string
        case custom(String)
    }
    
    /// Temporal constraints for pattern matching
    struct TemporalConstraints: Hashable, Codable {
        /// Required time range for matches
        var timeRange: ClosedRange<Date>?
        
        /// Required temporal sequence
        var sequence: [TemporalStep]?
        
        /// Maximum allowed time gap between steps
        var maxTimeGap: TimeInterval?
        
        struct TemporalStep: Hashable, Codable {
            let nodePatternIndex: Int
            let duration: TimeInterval?
            let relativeTiming: RelativeTiming?
            
            enum RelativeTiming: Hashable, Codable {
                case before(nodePatternIndex: Int)
                case after(nodePatternIndex: Int)
                case concurrent(nodePatternIndex: Int)
            }
        }
    }
    
    /// Semantic constraints for pattern matching
    struct SemanticConstraints: Hashable, Codable {
        /// Required concepts that must be present
        var requiredConcepts: Set<String>
        
        /// Required semantic relationships between nodes
        var relationships: [SemanticRelation]
        
        /// Minimum semantic similarity between nodes
        var minimumSimilarity: Float?
        
        struct SemanticRelation: Hashable, Codable {
            let sourcePatternIndex: Int
            let targetPatternIndex: Int
            let relationType: RelationType
            let strength: Float
            
            enum RelationType: String, Codable {
                case synonym
                case antonym
                case broader
                case narrower
                case related
            }
        }
    }
    
    // MARK: - Initialization
    
    init(
        nodePatterns: [NodePattern],
        connectionPatterns: [ConnectionPattern],
        temporalConstraints: TemporalConstraints? = nil,
        semanticConstraints: SemanticConstraints? = nil,
        minimumConfidence: Float = 0.5
    ) {
        self.id = UUID()
        self.nodePatterns = nodePatterns
        self.connectionPatterns = connectionPatterns
        self.temporalConstraints = temporalConstraints
        self.semanticConstraints = semanticConstraints
        self.minimumConfidence = minimumConfidence
    }
    
    // MARK: - Pattern Validation
    
    /// Validates that the pattern is well-formed
    func validate() throws {
        // Validate node patterns
        guard !nodePatterns.isEmpty else {
            throw QueryError.invalidPattern("Pattern must contain at least one node pattern")
        }
        
        // Validate connection patterns
        for connection in connectionPatterns {
            guard connection.sourcePatternIndex < nodePatterns.count,
                  connection.targetPatternIndex < nodePatterns.count else {
                throw QueryError.invalidPattern("Connection pattern references invalid node pattern index")
            }
        }
        
        // Validate temporal constraints
        if let temporal = temporalConstraints {
            for step in temporal.sequence ?? [] {
                guard step.nodePatternIndex < nodePatterns.count else {
                    throw QueryError.invalidPattern("Temporal step references invalid node pattern index")
                }
            }
        }
        
        // Validate semantic constraints
        if let semantic = semanticConstraints {
            for relation in semantic.relationships {
                guard relation.sourcePatternIndex < nodePatterns.count,
                      relation.targetPatternIndex < nodePatterns.count else {
                    throw QueryError.invalidPattern("Semantic relation references invalid node pattern index")
                }
            }
        }
    }
    
    enum QueryError: Error {
        case invalidPattern(String)
    }
}

// MARK: - Pattern Building Helper

extension QueryPattern {
    /// Builder class to help construct query patterns
    class Builder {
        private var nodePatterns: [NodePattern] = []
        private var connectionPatterns: [ConnectionPattern] = []
        private var temporalConstraints: TemporalConstraints?
        private var semanticConstraints: SemanticConstraints?
        private var minimumConfidence: Float = 0.5
        
        /// Adds a node pattern to match
        @discardableResult
        func addNodePattern(
            type: NodeType,
            value: String? = nil,
            metadata: [String: MetadataConstraint] = [:]
        ) -> Builder {
            let pattern = NodePattern(
                nodeType: type,
                valuePattern: value,
                metadataConstraints: metadata
            )
            nodePatterns.append(pattern)
            return self
        }
        
        /// Adds a connection pattern between nodes
        @discardableResult
        func addConnectionPattern(
            from: Int,
            to: Int,
            type: MetadataRelationType,
            minWeight: Float? = nil
        ) -> Builder {
            let pattern = ConnectionPattern(
                relationType: type,
                sourcePatternIndex: from,
                targetPatternIndex: to,
                minimumWeight: minWeight,
                metadataConstraints: [:],
                allowIndirect: false
            )
            connectionPatterns.append(pattern)
            return self
        }
        
        /// Sets temporal constraints for the pattern
        @discardableResult
        func withTemporalConstraints(_ constraints: TemporalConstraints) -> Builder {
            self.temporalConstraints = constraints
            return self
        }
        
        /// Sets semantic constraints for the pattern
        @discardableResult
        func withSemanticConstraints(_ constraints: SemanticConstraints) -> Builder {
            self.semanticConstraints = constraints
            return self
        }
        
        /// Sets minimum confidence required for matches
        @discardableResult
        func withMinimumConfidence(_ confidence: Float) -> Builder {
            self.minimumConfidence = confidence
            return self
        }
        
        /// Builds and validates the query pattern
        func build() throws -> QueryPattern {
            let pattern = QueryPattern(
                nodePatterns: nodePatterns,
                connectionPatterns: connectionPatterns,
                temporalConstraints: temporalConstraints,
                semanticConstraints: semanticConstraints,
                minimumConfidence: minimumConfidence
            )
            try pattern.validate()
            return pattern
        }
    }
}

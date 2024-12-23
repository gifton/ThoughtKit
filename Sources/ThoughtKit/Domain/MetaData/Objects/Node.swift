//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/3/24.
//

import Foundation

/// Defines the basic structure for any node in the metadata network.
/// Nodes are the vertices in our graph structure and can represent thoughts,
/// keywords, topics, or any other metadata type that we want to track relationships between.
/// All nodes must be uniquely identifiable and support equality comparison.
protocol Node: Identifiable, Hashable {
    var id: UUID { get }
    var type: NodeType { get }
    var connections: Set<MetadataConnection> { get set }  // Made concrete type
}

/// Defines the different types of nodes that can exist in the network.
/// This enum helps categorize nodes and enables type-specific querying.
/// For example, we can find all keyword nodes or all topic nodes.
enum NodeType: String, Codable, Hashable {
    case thought    // Reference to Core Data thought
    case keyword
    case topic
    case sentiment
    case location
    case person
    case date
    case organization
    case event
    case category
    case emotion
    case activity
    case summary
    case timeReference
    case humanRelationship
    case goal
    case decision
    case challenge
    case insight
    case resource
}

/// Concrete implementation of a Node that stores metadata about thoughts and their relationships.
/// This structure maintains information about a single node in the network, including
/// its relationships with other nodes and usage statistics.
/// Enhanced MetadataNode with improved relationship handling and metadata management
struct MetadataNode: Node, Codable {
    // MARK: - Core Properties
    let id: UUID
    let type: NodeType
    let value: String
    var connections: Set<MetadataConnection>
    let createdAt: Date
    
    // MARK: - Relationship Management
    var incomingEdges: Set<UUID>
    var outgoingEdges: Set<UUID>
    var bidirectionalEdges: Set<UUID>
    
    // MARK: - Node Statistics
    var frequency: Int
    var lastUsed: Date
    var accessCount: Int
    var strength: Float  // Overall node strength/importance in the graph
    
    // MARK: - Metadata Management
    var metadata: TypedMetadata?
    var contextualMetadata: ContextualMetadata?
    var tags: Set<String>
    
    // MARK: - Temporal Tracking
    var validityPeriod: ClosedRange<Date>?
    var temporalContext: TemporalContext?
    var lastModified: Date
    
    // MARK: - Semantic Properties
    var semanticContext: SemanticContext?
    var embeddings: [Float]?  // Vector representation for similarity calculations
    
    // MARK: - Graph Analysis Properties
    var centrality: Float = 0.0  // Measure of node importance in graph
    var clusterCoefficient: Float = 0.0  // Measure of node clustering
    var communityID: UUID?  // ID of the community this node belongs to
    
    // MARK: - Validation and Quality
    var confidence: Float
    var validationStatus: ValidationStatus
    var qualityMetrics: QualityMetrics
    
    // MARK: - Initialization
    
    init(id: UUID = UUID(),
         type: NodeType,
         value: String,
         metadata: TypedMetadata = TypedMetadata()) {
        self.id = id
        self.type = type
        self.value = value
        self.connections = []
        self.createdAt = Date()
        
        // Initialize relationship sets
        self.incomingEdges = []
        self.outgoingEdges = []
        self.bidirectionalEdges = []
        
        // Initialize statistics
        self.frequency = 1
        self.lastUsed = Date()
        self.accessCount = 0
        self.strength = 1.0
        
        // Initialize metadata
        self.metadata = metadata
        self.contextualMetadata = .init()
        self.tags = []
        
        // Initialize temporal properties
        self.lastModified = Date()
        
        // Initialize validation properties
        self.confidence = 1.0
        self.validationStatus = .valid
        self.qualityMetrics = QualityMetrics()
    }
    
    // MARK: - Nested Types
    
    struct QualityMetrics: Codable {
        var accuracy: Float = 1.0
        var completeness: Float = 1.0
        var consistency: Float = 1.0
        var reliability: Float = 1.0
    }
    
    enum ValidationStatus: String, Codable {
        case valid
        case invalid
        case pending
        case expired
    }
    
    // MARK: - Methods
    
    /// Updates node statistics and metadata after access
    mutating func recordAccess() {
        self.lastUsed = Date()
        self.accessCount += 1
        updateStrength()
    }
    
    /// Adds a new connection to the node
    mutating func addConnection(_ connection: MetadataConnection) {
        connections.insert(connection)
        
        // Update edge sets based on connection type
        if connection.type.isBidirectional {
            bidirectionalEdges.insert(connection.id)
        } else if connection.sourceId == id {
            outgoingEdges.insert(connection.id)
        } else {
            incomingEdges.insert(connection.id)
        }
        
        updateStrength()
    }
    
    /// Removes a connection from the node
    mutating func removeConnection(_ connectionId: UUID) {
        
//        connections.removeAll { $0.id == connectionId }
        incomingEdges.remove(connectionId)
        outgoingEdges.remove(connectionId)
        bidirectionalEdges.remove(connectionId)
        updateStrength()
    }
    
    /// Updates the node's strength based on its connections and metadata
    private mutating func updateStrength() {
        let connectionStrength = Float(connections.count) / 100.0
        let frequencyFactor = Float(frequency) / 10.0
        let recencyFactor = calculateRecencyFactor()
        
        strength = (connectionStrength + frequencyFactor + recencyFactor) / 3.0
        strength = min(max(strength, 0.0), 1.0)
    }
    
    private func calculateRecencyFactor() -> Float {
        let daysSinceLastUse = Date().timeIntervalSince(lastUsed) / (24 * 3600)
        return Float(exp(-daysSinceLastUse / 30.0)) // Exponential decay over 30 days
    }
    
    /// Updates graph analysis metrics
    mutating func updateGraphMetrics(neighbors: Set<MetadataNode>) {
        updateCentrality(neighbors: neighbors)
        updateClusterCoefficient(neighbors: neighbors)
    }
    
    private mutating func updateCentrality(neighbors: Set<MetadataNode>) {
        let degree = Float(connections.count)
        let maxPossibleDegree = Float(neighbors.count)
        centrality = maxPossibleDegree > 0 ? degree / maxPossibleDegree : 0
    }
    
    private mutating func updateClusterCoefficient(neighbors: Set<MetadataNode>) {
        guard neighbors.count > 1 else {
            clusterCoefficient = 0
            return
        }
        
        let neighborConnections = neighbors.reduce(0) { count, neighbor in
            count + neighbors.filter { neighbor.isConnectedTo(node: $0) }.count
        }
        
        let maxPossibleConnections = neighbors.count * (neighbors.count - 1)
        clusterCoefficient = maxPossibleConnections > 0 ?
            Float(neighborConnections) / Float(maxPossibleConnections) : 0
    }
    
    /// Checks if this node is connected to another node
    func isConnectedTo(node: MetadataNode) -> Bool {
        connections.contains { $0.targetId == node.id || $0.sourceId == node.id }
    }
    
    /// Gets all connections of a specific type
    func connections(ofType type: MetadataRelationType) -> Set<MetadataConnection> {
        connections.filter { $0.type == type }
    }
    
    /// Gets the strength of connection to another node
    func connectionStrength(to nodeId: UUID) -> Float {
        connections
            .first { $0.targetId == nodeId || $0.sourceId == nodeId }?
            .weight ?? 0
    }
    
    /// Validates the node and updates validation status
    mutating func validate() -> Bool {
        let isValueValid = !value.isEmpty
        let isTypeValid = type != .thought || connections.contains { $0.type == .has }
        let isTemporallyValid = validityPeriod.map { $0.contains(Date()) } ?? true
        
        validationStatus = isValueValid && isTypeValid && isTemporallyValid ? .valid : .invalid
        return validationStatus == .valid
    }
}

// MARK: - Hashable Implementation
extension MetadataNode {
    static func == (lhs: MetadataNode, rhs: MetadataNode) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Analysis Extensions
extension MetadataNode {
    /// Calculates semantic similarity with another node
    func semanticSimilarity(to other: MetadataNode) -> Float {
        guard let embeddings = self.embeddings,
              let otherEmbeddings = other.embeddings,
              embeddings.count == otherEmbeddings.count else {
            return 0
        }
        
        // Cosine similarity calculation
        let dotProduct = zip(embeddings, otherEmbeddings)
            .map { $0 * $1 }
            .reduce(0, +)
        
        let magnitude1 = sqrt(embeddings.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(otherEmbeddings.map { $0 * $0 }.reduce(0, +))
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0 }
        return dotProduct / (magnitude1 * magnitude2)
    }
    
    /// Gets all paths to another node up to a certain depth
    func findPaths(to target: MetadataNode, maxDepth: Int = 3) -> [[MetadataConnection]] {
        var paths: [[MetadataConnection]] = []
        var visited = Set<UUID>()
        
        func dfs(current: [MetadataConnection]) {
            guard current.count < maxDepth else { return }
            
            let lastNode = current.last?.targetId ?? id
            guard !visited.contains(lastNode) else { return }
            
            visited.insert(lastNode)
            
            if lastNode == target.id {
                paths.append(current)
                return
            }
            
            for connection in connections where !visited.contains(connection.targetId) {
                var newPath = current
                newPath.append(connection)
                dfs(current: newPath)
            }
            
            visited.remove(lastNode)
        }
        
        dfs(current: [])
        return paths
    }
}

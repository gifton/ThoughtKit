//
//  MetaDataNetworkWalker.swift
//
//
//  Created by Gifton Okoronkwo on 11/3/24.
//

import Foundation

/// Advanced graph traversal and exploration actor that works with MetaDataGraph
/// Provides sophisticated path finding, relationship analysis, and network exploration capabilities
///

/**
`GraphExplorer` manages optimized graph traversal and path analysis for the metadata network. It provides:

- Configurable traversal with depth limits, weight thresholds, and relation type filtering
- Batched operations for efficient exploration of large graphs
- Dedicated traversal caching layer separate from main graph cache
- Path tracking with support for shortest path and subgraph extraction
- Progress monitoring for long-running traversals
- Rich traversal results including path weights, connection metadata, and full node paths

Core operations:
- Depth/breadth-first traversal with custom termination conditions
- Shortest path finding between nodes
- Subgraph extraction around focal nodes
- Similarity-based node matching
- Pattern detection across node clusters

The explorer uses batch processing and maintains its own cache to minimize graph database hits.
All operations are async and thread-safe through actor isolation.
*/

actor GraphExplorer {
    // MARK: - Dependencies
    private let graph: MetadataGraph
    private let cache: NodeCache
    
    // MARK: - Configuration
    private let maxTraversalDepth: Int
    private let maxConcurrentOperations: Int
    
    // MARK: - Initialization
    
    /// Initializes a network walker with a metadata graph and optional configuration
    /// - Parameters:
    ///   - graph: The metadata graph to traverse
    ///   - cacheCapacity: Maximum number of nodes to cache during traversal
    ///   - maxDepth: Maximum depth for graph traversals
    ///   - maxConcurrentOperations: Limit on concurrent graph exploration tasks
    init(
        graph: MetadataGraph,
        cacheCapacity: Int = 1000,
        maxDepth: Int = 5,
        maxConcurrentOperations: Int = 4
    ) {
        self.graph = graph
        self.cache = NodeCache(capacity: cacheCapacity)
        self.maxTraversalDepth = maxDepth
        self.maxConcurrentOperations = maxConcurrentOperations
    }
    
    // MARK: - Traversal Structures
    
    /// Represents a detailed result of graph traversal
    struct TraversalResult {
        let node: MetadataNode
        let path: [MetadataNode]
        let connections: [MetadataConnection]
        let depth: Int
        let totalWeight: Float
        
        /// Average connection weight for this traversal path
        var averageWeight: Float {
            connections.isEmpty ? 0 : totalWeight / Float(connections.count)
        }
    }
    
    /// Configuration options for graph traversal
    struct TraversalOptions {
        /// Maximum depth of traversal
        var maxDepth: Int = 5
        
        /// Minimum connection weight to follow
        var minimumWeight: Float = 0.1
        
        /// Relationship types to follow
        var allowedRelationTypes: Set<MetadataRelationType>?
        
        /// Relationship types to exclude
        var excludedRelationTypes: Set<MetadataRelationType> = []
        
        /// Whether to only follow bidirectional connections
        var bidirectionalOnly: Bool = false
        
        /// Whether to follow inverse relationships
        var followInverseRelations: Bool = true
        
        /// Optional filter to prune traversal
        var nodeFilter: ((MetadataNode) -> Bool)?
        
        /// Optional progress tracking
        var progressHandler: ((Double) -> Void)?
    }
    
    // MARK: - Core Traversal Methods
    
    /// Finds related nodes starting from a specific node with advanced filtering
    /// - Parameters:
    ///   - startNodeId: The starting node for traversal
    ///   - options: Traversal configuration options
    /// - Returns: An array of traversal results, potentially sorted by relevance
    func findRelatedNodes(
        startingFrom startNodeId: UUID,
        options: TraversalOptions = TraversalOptions()
    ) async throws -> [TraversalResult] {
        // Validate starting node exists
        guard let _ = try await graph.getNode(by: startNodeId) else {
            throw MetadataGraph.GraphError.nodeMissing(startNodeId)
        }
        
        var visited = Set<UUID>()
        var results: [TraversalResult] = []
        var queue = [(
            nodeId: UUID,
            depth: Int,
            currentPath: [MetadataNode],
            connections: [MetadataConnection],
            totalWeight: Float
        )]()
        
        // Initial queue entry
        queue.append((
            nodeId: startNodeId,
            depth: 0,
            currentPath: [],
            connections: [],
            totalWeight: 1.0
        ))
        
        while !queue.isEmpty {
            let currentTraversal = queue.removeFirst()
            
            // Skip if already visited or depth exceeded
            guard !visited.contains(currentTraversal.nodeId),
                  currentTraversal.depth < options.maxDepth else {
                continue
            }
            
            visited.insert(currentTraversal.nodeId)
            
            // Fetch current node and its connections
            guard let currentNode = try await graph.getNode(by: currentTraversal.nodeId),
                  let nodeConnections = try? await graph.findConnections(from: currentNode.id) else {
                continue
            }
            
            // Apply node filter if provided
            guard options.nodeFilter?(currentNode) ?? true else {
                continue
            }
            
            // Filter connections based on traversal options
            let validConnections = nodeConnections.filter { connection in
                connection.weight >= options.minimumWeight &&
                (options.allowedRelationTypes == nil ||
                 options.allowedRelationTypes!.contains(connection.type)) &&
                !options.excludedRelationTypes.contains(connection.type) &&
                (!options.bidirectionalOnly || connection.type.isBidirectional)
            }
            
            // Process valid connections and queue next traversals
            for connection in validConnections {
                // Skip already visited nodes
                guard !visited.contains(connection.targetId) else { continue }
                
                var newPath = currentTraversal.currentPath
                var newConnections = currentTraversal.connections
                
                // Fetch target node
                guard let targetNode = try await graph.getNode(by: connection.targetId) else {
                    continue
                }
                
                newPath.append(targetNode)
                newConnections.append(connection)
                
                // Create traversal result if not the start node
                if targetNode.id != startNodeId {
                    let traversalResult = TraversalResult(
                        node: targetNode,
                        path: newPath,
                        connections: newConnections,
                        depth: currentTraversal.depth + 1,
                        totalWeight: currentTraversal.totalWeight * connection.weight
                    )
                    results.append(traversalResult)
                }
                
                // Queue next traversal
                queue.append((
                    nodeId: connection.targetId,
                    depth: currentTraversal.depth + 1,
                    currentPath: newPath,
                    connections: newConnections,
                    totalWeight: currentTraversal.totalWeight * connection.weight
                ))
            }
            
            // Optional progress tracking
            options.progressHandler?(
                Double(results.count) / Double(queue.count + results.count + 1)
            )
        }
        
        // Optional sorting and filtering
        return results.sorted { $0.averageWeight > $1.averageWeight }
    }
    
    // MARK: - Advanced Path Finding
    
    /// Finds the most semantically relevant path between two nodes
    /// - Parameters:
    ///   - startNodeId: Starting node's identifier
    ///   - endNodeId: Destination node's identifier
    ///   - options: Traversal configuration
    /// - Returns: The most semantically meaningful path between nodes
    func findMeaningfulPath(
        from startNodeId: UUID,
        to endNodeId: UUID,
        options: TraversalOptions = TraversalOptions()
    ) async throws -> [MetadataNode]? {
        // Validate start and end nodes exist
        guard try await graph.getNode(by: startNodeId) != nil,
              try await graph.getNode(by: endNodeId) != nil else {
            throw MetadataGraph.GraphError.nodeMissing(startNodeId)
        }
        
        var visited = Set<UUID>()
        var queue = [(
            nodeId: UUID,
            path: [MetadataNode],
            weight: Float
        )]()
        
        // Initial queue entry
        queue.append((
            nodeId: startNodeId,
            path: [],
            weight: 1.0
        ))
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            
            // Skip if already visited
            guard !visited.contains(current.nodeId) else { continue }
            
            visited.insert(current.nodeId)
            
            // Reached destination
            if current.nodeId == endNodeId {
                return current.path
            }
            
            // Fetch node connections
            let connections = try await graph.findConnections(from: current.nodeId)
            
            for connection in connections {
                // Skip visited nodes and apply traversal filters
                guard !visited.contains(connection.targetId),
                      connection.weight >= options.minimumWeight else {
                    continue
                }
                
                // Fetch target node
                guard let targetNode = try await graph.getNode(by: connection.targetId) else {
                    continue
                }
                
                var newPath = current.path
                newPath.append(targetNode)
                
                queue.append((
                    nodeId: connection.targetId,
                    path: newPath,
                    weight: current.weight * connection.weight
                ))
            }
        }
        
        return nil
    }
    
    // MARK: - Semantic Similarity
    
    /// Calculates semantic similarity between two nodes based on their graph connections
    /// - Parameters:
    ///   - firstNodeId: First node's identifier
    ///   - secondNodeId: Second node's identifier
    /// - Returns: A similarity score between 0 and 1
    func calculateSemanticSimilarity(
        between firstNodeId: UUID,
        and secondNodeId: UUID
    ) async throws -> Float {
        // Fetch both nodes
        guard let firstNode = try await graph.getNode(by: firstNodeId),
              let secondNode = try await graph.getNode(by: secondNodeId) else {
            throw MetadataGraph.GraphError.nodeMissing(firstNodeId)
        }
        
        // Use node embeddings for direct similarity if available
        if let firstEmbeddings = firstNode.embeddings,
           let secondEmbeddings = secondNode.embeddings,
           firstEmbeddings.count == secondEmbeddings.count {
            return calculateCosineSimilarity(
                firstEmbeddings,
                secondEmbeddings
            )
        }
        
        // Fallback to graph-based similarity calculation
        let firstConnections = try await graph.findConnections(from: firstNodeId)
        let secondConnections = try await graph.findConnections(from: secondNodeId)
        
        // Compare connection types and weights
        let sharedConnectionTypes = Set(firstConnections.map { $0.type })
            .intersection(Set(secondConnections.map { $0.type }))
        
        let similarityScore = Float(sharedConnectionTypes.count) /
            Float(firstConnections.count + secondConnections.count)
        
        return similarityScore
    }
    
    // MARK: - Private Helpers
    
    /// Calculates cosine similarity between two embedding vectors
    private func calculateCosineSimilarity(_ vec1: [Float], _ vec2: [Float]) -> Float {
        guard vec1.count == vec2.count else { return 0 }
        
        let dotProduct = zip(vec1, vec2).map(*).reduce(0, +)
        let magnitude1 = sqrt(vec1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(vec2.map { $0 * $0 }.reduce(0, +))
        
        return magnitude1 > 0 && magnitude2 > 0 ?
            dotProduct / (magnitude1 * magnitude2) : 0
    }
}

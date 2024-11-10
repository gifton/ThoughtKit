

import Foundation

/// Actor to safely track visited nodes during traversal
private actor VisitedTracker {
    private var visited: Set<UUID> = []
    
    func isVisited(_ id: UUID) -> Bool {
        visited.contains(id)
    }
    
    func markVisited(_ ids: [UUID]) {
        visited.formUnion(ids)
    }
    
    func clear() {
        visited.removeAll()
    }
}


/// Optimized graph walker with support for different connection types and relationship analysis
actor OptimizedGraphWalker {
    
    private let store: MetadataNetworkStore
    private let cache: NodeCache
    private let batchSize: Int
    
    struct GraphWalkOptions {
        var maxDepth: Int = 5
        var minimumWeight: Float = 0.1
        var sortByWeight: Bool = true
        var limit: Int? = nil
        var allowedRelationTypes: Set<MetadataRelationType>? = nil
        var excludedRelationTypes: Set<MetadataRelationType> = []
        var bidirectionalOnly: Bool = false
        var followInverseRelations: Bool = true
    }
    
    struct GraphTraversalResult {
        let node: MetadataNode
        let depth: Int
        let connections: [MetadataConnection]
        let totalWeight: Float
        let path: [MetadataNode]
        
        var averageWeight: Float {
            Float(connections.count) > 0 ? totalWeight / Float(connections.count) : 0
        }
    }
    
    init(store: MetadataNetworkStore, cacheCapacity: Int = 1000, batchSize: Int = 50) {
        self.store = store
        self.cache = NodeCache(capacity: cacheCapacity)
        self.batchSize = batchSize
    }
    
    enum GraphTraversalError: Error {
        case nodeNotFound(UUID)
        case invalidStartNode
    }
    
    private func resolvePathNodes(_ path: [UUID]) async throws -> [MetadataNode] {
        try await path.asyncMap { id in
            if let cached = await self.cache.get(id) { return cached.node }
            guard let node = try await self.store.getNode(by: id) else {
                throw GraphTraversalError.nodeNotFound(id)
            }
            return node
        }
    }
    
    private func getNodeWithConnections(_ id: UUID) async throws -> (MetadataNode, [MetadataConnection])? {
        // Check cache first
        if let cached = await cache.get(id) {
            return cached
        }
        
        // Fetch from store if not cached
        guard let node = try await store.getNode(by: id) else { return nil }
        let connections = try await store.findConnections(from: id)
        
        // Cache the result
        await cache.set(id, node: node, connections: connections)
        
        return (node, connections)
    }
    
    private func isValidConnection(_ connection: MetadataConnection, options: GraphWalkOptions) -> Bool {
        // Check if connection type is allowed
        if let allowedTypes = options.allowedRelationTypes,
           !allowedTypes.contains(connection.type) {
            return false
        }
        
        // Check if connection type is excluded
        if options.excludedRelationTypes.contains(connection.type) {
            return false
        }
        
        // Check bidirectional requirement
        if options.bidirectionalOnly && !connection.type.isBidirectional {
            return false
        }
        
        // Check weight threshold
        if connection.weight < options.minimumWeight {
            return false
        }
        
        return true
    }
    
    func findRelatedNodes(
            startingFrom nodeId: UUID,
            options: GraphWalkOptions = GraphWalkOptions(),
            progress: ((Double) -> Void)? = nil
        ) async throws -> [GraphTraversalResult] {
            let visitedTracker = VisitedTracker()
            var results: [GraphTraversalResult] = []
            var queue = [(node: UUID, depth: Int, weight: Float, connections: [MetadataConnection], path: [UUID])]()
            
            // Start with the initial node
            guard let (startNode, _) = try await getNodeWithConnections(nodeId) else {
                throw GraphTraversalError.invalidStartNode
            }
            
            queue.append((nodeId, 0, 1.0, [], [nodeId]))
            
            while !queue.isEmpty {
                let batch = Array(queue.prefix(batchSize))
                queue.removeFirst(min(batchSize, queue.count))
                
                // Process batch concurrently
                let newPaths = try await batch.asyncConcurrentMap { current -> [(UUID, Int, Float, [MetadataConnection], [UUID])] in
                    let (currentId, depth, weight, previousConnections, path) = current
                    
                    guard let (node, connections) = try await self.getNodeWithConnections(currentId),
                          !(await visitedTracker.isVisited(currentId)),
                          depth <= options.maxDepth else {
                        return []
                    }
                    
                    // Process connections concurrently
                    let validConnections = connections.filter {
                        self.isValidConnection($0, options: options)
                    }
                    
                    let newPathsForNode = try await validConnections.asyncConcurrentMap { connection -> (UUID, Int, Float, [MetadataConnection], [UUID])? in
                        let targetId = connection.targetId
                        guard !(await visitedTracker.isVisited(targetId)) else {
                            return nil
                        }
                        
                        var updatedConnections = previousConnections
                        updatedConnections.append(connection)
                        
                        // Handle inverse relations if enabled
                        if options.followInverseRelations,
                           let inverseType = connection.type.inverse {
                            let inverseConnection = MetadataConnection(
                                id: UUID(),
                                sourceId: connection.targetId,
                                targetId: connection.sourceId,
                                type: inverseType,
                                weight: connection.weight,
                                createdAt: connection.createdAt,
                                lastAccessed: Date(),
                                occurrences: connection.occurrences,
                                confidence: connection.confidence,
                                metadata: connection.metadata
                            )
                            updatedConnections.append(inverseConnection)
                        }
                        
                        return (
                            targetId,
                            depth + 1,
                            weight * connection.weight,
                            updatedConnections,
                            path + [targetId]
                        )
                    }
                    
                    return newPathsForNode.compactMap { $0 }
                }
                
                // Flatten and add new paths to queue
                queue.append(contentsOf: newPaths.flatMap { $0 })
                
                // Mark nodes as visited
                await visitedTracker.markVisited(batch.map { $0.node })
                
                // Process results for this batch
                let batchResults = try await batch.asyncMap { item -> GraphTraversalResult? in
                    let (nodeId, depth, weight, connections, path) = item
                    guard nodeId != startNode.id,
                          let (node, _) = try await self.getNodeWithConnections(nodeId) else {
                        return nil
                    }
                    
                    let pathNodes = try await self.resolvePathNodes(path)
                    return GraphTraversalResult(
                        node: node,
                        depth: depth,
                        connections: connections,
                        totalWeight: weight,
                        path: pathNodes
                    )
                }
                
                results.append(contentsOf: batchResults.compactMap { $0 })
                
                // Update progress if handler provided
                if let progress = progress {
                    let totalEstimated = Float(queue.count + results.count)
                    let completed = Float(results.count)
                    progress(Double(completed / totalEstimated))
                }
            }
            
            // Apply sorting and limits
            var finalResults = results
            if options.sortByWeight {
                finalResults.sort { $0.averageWeight > $1.averageWeight }
            }
            if let limit = options.limit {
                finalResults = Array(finalResults.prefix(limit))
            }
            
            progress?(1.0) // Signal completion
            return finalResults
        }
}

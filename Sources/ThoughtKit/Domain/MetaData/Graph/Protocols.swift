//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/23/24.
//

import Foundation

// MARK: - Core Protocol
protocol MetadataGraphProtocol: Actor {
    // Node Operations
    func getNode(by id: UUID) async throws -> MetadataNode?
    func findNode(withValue: String, type: NodeType) async throws -> MetadataNode?
    func addNode(_ value: String, type: NodeType, metadata: TypedMetadata?) async throws -> UUID
    func updateNode(_ node: MetadataNode) async throws
    func deleteNode(_ id: UUID) async throws
    
    // Connection Operations
    func connect(sourceId: UUID, targetId: UUID, type: MetadataRelationType, weight: Float) async throws -> UUID
    func findConnections(from sourceId: UUID, relationshipTypes: Set<MetadataRelationType>?, minWeight: Float) async throws -> [MetadataConnection]
    func updateConnection(_ connection: MetadataConnection) async throws
    func deleteConnection(_ id: UUID) async throws
    
    // Transaction Management
    func beginTransaction() async throws -> UUID
    func commitTransaction() async throws
    func rollbackTransaction() async throws
    
    // Query Operations
    func findNodes(matching criteria: QueryCriteria) async throws -> [MetadataNode]
    func findPaths(from sourceId: UUID, to targetId: UUID, maxDepth: Int) async throws -> [[MetadataConnection]]
    func findRelated(to nodeId: UUID, types: Set<NodeType>) async throws -> [RelatedNode]
}

// MARK: - Maintenance Protocol
protocol GraphMaintainable: Actor {
    var maintenanceSchedule: MaintenanceSchedule { get set }
    var lastMaintenanceRun: Date { get }
    
    // Maintenance Operations
    func performMaintenance() async throws
    func scheduleMaintenanceTask(_ task: MaintenanceTask, priority: TaskPriority) async
    func cancelMaintenanceTask(_ id: UUID) async
    
    // Cleanup Operations
    func cleanupOrphanedNodes() async throws -> Int
    func pruneStaleConnections(olderThan age: TimeInterval) async throws -> Int
    func compactStorage() async throws
    func optimizeIndexes() async throws
    
    // Validation
    func validateGraphIntegrity() async throws -> ValidationReport
    func repairInconsistencies(_ issues: [ValidationReport.ValidationIssue]) async throws
    
    // History
    func getMaintenanceHistory(since: Date) async -> [MaintenanceRecord]
    func clearMaintenanceHistory() async
}

// MARK: - Metrics Protocol
protocol GraphMetricsProvider: Actor {
    var metrics: GraphMetrics { get set }
    
    // Operational Metrics
    func recordOperation(_ type: MetadataGraph.GraphMetrics.OperationType)
    func recordError(_ type: MetadataGraph.GraphMetrics.ErrorType)
    func getOperationCounts() async -> [MetadataGraph.GraphMetrics.OperationType: Int]
    func getErrorCounts() async -> [MetadataGraph.GraphMetrics.ErrorType: Int]
    
    // Performance Metrics
    func getQueryLatencies() async -> [String: TimeInterval]
    func getCacheStats() async -> CacheStats
    func getStorageStats() async -> StorageStats
    
    // Graph Metrics
    func getGraphStats() async -> GraphStats
    func getNodeDistribution() async -> [NodeType: Int]
    func getConnectionDistribution() async -> [MetadataRelationType: Int]
    
    // Health Metrics
    func getHealthReport() async -> HealthReport
    func getPerformanceMetrics() async -> PerformanceMetrics
}

// MARK: - Analytics Protocol
protocol GraphAnalytics: Actor {
    // Pattern Analysis
    func detectPatterns() async throws -> [Pattern]
    func findSimilarPatterns(to pattern: Pattern) async throws -> [Pattern]
    func validatePattern(_ pattern: Pattern) async throws -> Bool
    
    // Network Analysis
    func calculateCentrality(for nodeId: UUID, method: CentralityMethod) async throws -> Float
    func detectCommunities(algorithm: CommunityDetection) async throws -> [Community]
    func findInfluentialNodes(limit: Int) async throws -> [MetadataNode]
    
    // Path Analysis
    func findShortestPath(from: UUID, to: UUID) async throws -> [MetadataConnection]?
    func calculatePathStrength(_ path: [MetadataConnection]) async throws -> Float
    
    // Temporal Analysis
    func analyzeTemporalPatterns() async throws -> [TemporalPattern]
    func findTimeBasedClusters() async throws -> [TimeCluster]
}

// MARK: - Query Protocol
protocol GraphQueryable: Actor {
    // Basic Queries
    func query(_ criteria: QueryCriteria) async throws -> [QueryResult]
    func executeRawQuery(_ query: String) async throws -> [QueryResult]
    
    // Advanced Queries
    func semanticSearch(_ text: String, threshold: Float) async throws -> [QueryResult]
    func patternMatch(_ pattern: QueryPattern) async throws -> [PatternMatch]
    func spatialQuery(_ bounds: SpatialBounds) async throws -> [QueryResult]
    
    // Query Management
    func explainQuery(_ criteria: QueryCriteria) async throws -> QueryPlan
    func optimizeQuery(_ criteria: QueryCriteria) async throws -> QueryCriteria
    func cacheQuery(_ criteria: QueryCriteria) async throws
}

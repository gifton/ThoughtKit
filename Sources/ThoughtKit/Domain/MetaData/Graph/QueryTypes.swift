//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/23/24.
//

import Foundation

// MARK: - Query Types
struct QueryCriteria {
    let nodeTypes: Set<NodeType>?
    let relationTypes: Set<MetadataRelationType>?
    let valuePattern: String?
    let metadata: TypedMetadata?
    let temporalRange: ClosedRange<Date>?
    let limit: Int?
    let offset: Int?
}

struct QueryResult {
    let nodes: [MetadataNode]
    let connections: [MetadataConnection]
    let score: Float?
    let context: QueryContext
}

struct QueryPlan {
    let steps: [QueryStep]
    let estimatedCost: Float
    let cacheUtilization: Float
    let suggestedIndexes: [String]
}

// MARK: - Maintenance Types
struct MaintenanceSchedule {
    var tasks: [ScheduledTask]
    var nextRun: Date
    var interval: TimeInterval
    
    struct ScheduledTask {
        let id: UUID
        let task: MaintenanceTask
        let priority: TaskPriority
        let nextRun: Date
    }
}

enum TaskPriority: Int {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
}

// MARK: - Analytics Types
struct Pattern {
    let id: UUID
    let nodes: Set<UUID>
    let connections: Set<UUID>
    let confidence: Float
    let context: PatternContext
}

enum CentralityMethod {
    case degree
    case betweenness
    case eigenvector
    case pageRank
}

enum CommunityDetection {
    case louvain
    case labelPropagation
    case hierarchical
}

struct Community {
    let id: UUID
    let nodes: Set<UUID>
    let centroid: UUID?
    let cohesion: Float
}

// MARK: - Metrics Types
struct GraphMetrics {
    var operationCounts: [MetadataGraph.GraphMetrics.OperationType: Int]
    var errors: [MetadataGraph.GraphMetrics.ErrorType: Int]
    var averageOperationTime: TimeInterval
    var queryLatencies: [String: TimeInterval]
    
    mutating func recordOperation(_ type: MetadataGraph.GraphMetrics.OperationType) { }
    mutating func recordError(_ type: MetadataGraph.GraphMetrics.ErrorType) { }
}

struct PerformanceMetrics {
    let queryResponseTimes: [String: TimeInterval]
    let cacheHitRate: Float
    let storageUtilization: Float
    let averageLatency: TimeInterval
}

struct CacheStats {
    let hitCount: Int
    let missCount: Int
    let evictionCount: Int
    let memoryUsage: Int
    
    var hitRate: Float {
        Float(hitCount) / Float(hitCount + missCount)
    }
}

struct StorageStats {
    let diskUsage: Int
    let nodeCount: Int
    let connectionCount: Int
    let fragmentationLevel: Float
}

// MARK: - Health Types
struct HealthReport {
    let status: HealthStatus
    let issues: [HealthIssue]
    let metrics: PerformanceMetrics
    let recommendations: [Recommendation]
}

enum HealthStatus {
    case healthy
    case degraded(reason: String)
    case critical(issues: [String])
}

struct HealthIssue {
    let severity: IssueSeverity
    let description: String
    let impact: String
    let recommendation: String
}

enum IssueSeverity: Int {
    case info = 0
    case warning = 1
    case error = 2
    case critical = 3
}

struct Recommendation {
    let action: MaintenanceTask
    let priority: TaskPriority
    let expectedImpact: String
    let estimatedDuration: TimeInterval
}

enum MaintenanceTask {
    case cleanup(CleanupTask)
    case optimization(OptimizationTask)
    case validation(ValidationTask)
    case repair(RepairTask)
    
    struct CleanupTask {
        let target: CleanupTarget
        let threshold: TimeInterval
        let force: Bool
    }
    
    struct OptimizationTask {
        let target: OptimizationTarget
        let threshold: Float
        let maxDuration: TimeInterval
    }
    
    struct ValidationTask {
        let scope: ValidationScope
        let depth: Int
        let repairMode: RepairMode
    }
    
    struct RepairTask {
        let issues: [ValidationReport.ValidationIssue]
        let strategy: RepairStrategy
        let maxAttempts: Int
    }
    
    enum CleanupTarget {
        case orphanedNodes
        case staleConnections
        case unusedCache
        case invalidReferences
        case all
    }
    
    enum OptimizationTarget {
        case indexes
        case storage
        case cache
        case queries
        case all
    }
    
    enum ValidationScope {
        case nodes
        case connections
        case integrity
        case consistency
        case all
    }
    
    enum RepairMode {
        case auto
        case manual
        case report
    }
    
    enum RepairStrategy {
        case conservative
        case aggressive
        case interactive
    }
}

struct PatternContext {
    let temporalRange: ClosedRange<Date>?
    let frequency: Int
    let confidence: Float
    let source: PatternSource
    let metadata: TypedMetadata
    
    // Pattern characteristics
    var stability: Float
    var growth: GrowthMetrics
    var evolution: [PatternState]
    
    struct GrowthMetrics {
        let rate: Float
        let acceleration: Float
        let trend: GrowthTrend
    }
    
    enum GrowthTrend {
        case emerging
        case stable
        case declining
        case cyclic(period: TimeInterval)
    }
    
    struct PatternState {
        let timestamp: Date
        let strength: Float
        let nodes: Set<UUID>
        let connections: Set<UUID>
    }
}

struct QueryStep {
    let type: StepType
    let estimatedCost: Float
    let dependencies: Set<UUID>
    let metadata: QueryStepMetadata
    
    enum StepType {
        case scan(target: ScanTarget)
        case filter(predicate: QueryPredicate<String>)
        case join(strategy: JoinStrategy)
        case sort(criteria: [SortCriterion])
        case aggregate(function: AggregateFunction)
    }
    
    enum ScanTarget {
        case fullGraph
        case nodeType(NodeType)
        case connectionType(MetadataRelationType)
        case index(name: String)
    }
    
    struct QueryPredicate<T: Codable & Hashable> {
        let field: String
        let operation: PredicateOperation<T> // TODO: Figure out generic form of this.
        let value: Any
    }
    
    enum JoinStrategy {
        case nested
        case hash
        case merge
    }
    
    struct SortCriterion {
        let field: String
        let ascend: Bool
    }
    
    enum AggregateFunction {
        case count
        case sum(field: String)
        case average(field: String)
        case collect(field: String)
    }
    
    struct QueryStepMetadata {
        let estimatedRows: Int
        let cacheHit: Bool
        let parallelizable: Bool
        let dependencies: [UUID]
    }
}


struct TimeCluster {
    let id: UUID
    let timeRange: ClosedRange<Date>
    let nodes: Set<UUID>
    let centroid: Date
    let density: Float
    var cohesion: Float
    
    struct ClusterMetrics {
        let temporalSpread: TimeInterval
        let nodeDistribution: [Date: Int]
        let stability: Float
    }
    
    let metrics: ClusterMetrics
}

struct PatternMatch {
    let pattern: Pattern
    let matches: [MatchResult]
    let confidence: Float
    let context: PatternContext
    
    struct MatchResult {
        let nodes: [UUID: UUID] // Pattern node ID -> Matched node ID
        let connections: [UUID: UUID] // Pattern connection ID -> Matched connection ID
        let score: Float
    }
}

struct TemporalPattern {
    let id: UUID
    let interval: TimeInterval
    let frequency: Int
    let confidence: Float
    let type: PatternType
    
    enum PatternType {
        case periodic(period: TimeInterval)
        case seasonal(season: TimeInterval)
        case trend(direction: TrendDirection)
        case sequence(steps: [TimeStep])
    }
    
    enum TrendDirection {
        case increasing(rate: Float)
        case decreasing(rate: Float)
        case stable
        case volatile(range: ClosedRange<Float>)
    }
    
    struct TimeStep {
        let duration: TimeInterval
        let nodes: Set<UUID>
        let probability: Float
    }
}

struct GraphStats {
    let timestamp: Date
    
    // Size metrics
    let nodeCount: Int
    let connectionCount: Int
    let nodeTypeCounts: [NodeType: Int]
    let connectionTypeCounts: [MetadataRelationType: Int]
    
    // Graph metrics
    let density: Float
    let averageDegree: Float
    let clusteringCoefficient: Float
    let diameter: Int
    
    // Performance metrics
    let averageQueryTime: TimeInterval
    let cacheHitRate: Float
    let storageUtilization: Float
    
    // Health indicators
    let orphanedNodeCount: Int
    let inconsistencyCount: Int
    let validationScore: Float
}

struct MaintenanceRecord {
    let id: UUID
    let taskType: MaintenanceTask
    let startTime: Date
    let duration: TimeInterval
    let result: MaintenanceResult
    let impact: MaintenanceImpact
    
    enum MaintenanceResult {
        case success(details: String)
        case failure(error: Error)
        case partial(completed: Float, reason: String)
    }
    
    struct MaintenanceImpact {
        let nodesAffected: Int
        let connectionsAffected: Int
        let storageReclaimed: Int?
        let performanceImprovement: Float?
    }
}

struct ValidationReport {
    let timestamp: Date
    let isValid: Bool
    let issues: [ValidationIssue]
    let metrics: ValidationMetrics
    let recommendations: [ValidationRecommendation]
    
    struct ValidationIssue {
        let id: UUID
        let severity: IssueSeverity
        let category: IssueCategory
        let description: String
        let location: IssueLocation
        let impact: String
    }
    
    enum IssueCategory {
        case integrity
        case consistency
        case performance
        case schema
        case reference
    }
    
    enum IssueLocation {
        case node(UUID)
        case connection(UUID)
        case cache
        case storage
        case general
    }
    
    struct ValidationMetrics {
        let totalChecks: Int
        let passedChecks: Int
        let duration: TimeInterval
        let coverage: Float
    }
    
    struct ValidationRecommendation {
        let issue: UUID
        let action: MaintenanceTask
        let priority: TaskPriority
        let estimatedImpact: String
    }
}

enum PredicateOperation<T: Codable & Hashable>: Hashable, Codable {
//    static func == (lhs: PredicateOperation<T>, rhs: PredicateOperation<T>) -> Bool {
//        lhs.hashValue == rhs.hashValue
//    }
    
    case equals(T)
    case notEquals(T)
    case greaterThan(T)
    case lessThan(T)
    case greaterThanOrEqual(T)
    case lessThanOrEqual(T)
    case contains(T)
    case notContains(T)
    case between(lower: T, upper: T)
    case `in`([T])
    case notIn([T])
    case matches(String) // Keep string for regex patterns
    case exists(Bool)
    
    // Comparable operations only available when T conforms to Comparable
    static func validate<U>(_ operation: PredicateOperation<U>) throws where U: Comparable {
        switch operation {
        case .greaterThan, .lessThan, .greaterThanOrEqual, .lessThanOrEqual, .between:
            // These operations are valid for Comparable types
            break
        default:
            // Other operations don't require Comparable conformance
            break
        }
    }
}

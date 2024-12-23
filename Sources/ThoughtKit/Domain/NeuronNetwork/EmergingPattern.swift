//
//  File.swift
//
//
//  Created by Gifton Okoronkwo on 11/16/24.
//

import Foundation

/// Represents an emerging pattern detected by the neural network component
struct EmergingPattern: Hashable {
    
    // MARK: - Core Properties
    let id: UUID
    let patternType: PatternType
    var confidence: Float
    var firstDetected: Date
    var lastUpdated: Date
    
    // MARK: - Pattern Characteristics
    var frequency: Int
    var growth: GrowthMetrics
    var stability: StabilityMetrics
    var significance: Float // 0.0 to 1.0
    
    // MARK: - Pattern Components
    var involvedNodes: Set<UUID>
    var centralNode: UUID?
    var supportingConnections: [NeuralConnection]
    var metadata: PatternMetadata
    
    // MARK: - Context
    var temporalContext: TemporalContext?
    var semanticContext: SemanticContext?
    var neuralContext: NeuralContext
    
    // MARK: - Hashable Implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(patternType)
        hasher.combine(confidence)
        hasher.combine(firstDetected)
        hasher.combine(lastUpdated)
        hasher.combine(frequency)
        hasher.combine(growth)
        hasher.combine(stability)
        hasher.combine(significance)
        hasher.combine(involvedNodes)
        hasher.combine(centralNode)
        hasher.combine(supportingConnections)
        hasher.combine(metadata)
        hasher.combine(temporalContext)
        hasher.combine(semanticContext)
        hasher.combine(neuralContext)
    }
    
    static func == (lhs: EmergingPattern, rhs: EmergingPattern) -> Bool {
        lhs.id == rhs.id &&
        lhs.patternType == rhs.patternType &&
        lhs.confidence == rhs.confidence &&
        lhs.firstDetected == rhs.firstDetected &&
        lhs.lastUpdated == rhs.lastUpdated &&
        lhs.frequency == rhs.frequency &&
        lhs.growth == rhs.growth &&
        lhs.stability == rhs.stability &&
        lhs.significance == rhs.significance &&
        lhs.involvedNodes == rhs.involvedNodes &&
        lhs.centralNode == rhs.centralNode &&
        lhs.supportingConnections == rhs.supportingConnections &&
        lhs.metadata == rhs.metadata &&
        lhs.temporalContext == rhs.temporalContext &&
        lhs.semanticContext == rhs.semanticContext &&
        lhs.neuralContext == rhs.neuralContext
    }
    
    // MARK: - Nested Types
    struct GrowthMetrics: Hashable, Codable {
        var rate: Float // Rate of pattern strengthening
        var acceleration: Float // Change in growth rate
        var sustainedPeriod: TimeInterval // How long pattern has been growing
        var projectedGrowth: Float? // Predicted future strength
        var growthStage: GrowthStage
        
        enum GrowthStage: String, Codable {
            case emerging // Early detection phase
            case accelerating // Rapid growth phase
            case stabilizing // Growth slowing, pattern establishing
            case mature // Stable, established pattern
            case declining // Pattern weakening
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(rate)
            hasher.combine(acceleration)
            hasher.combine(sustainedPeriod)
            hasher.combine(projectedGrowth)
            hasher.combine(growthStage)
        }
    }
    
    struct StabilityMetrics: Hashable, Codable {
        var score: Float // Overall stability score (0.0 to 1.0)
        var volatility: Float // How much the pattern fluctuates
        var persistence: TimeInterval // How long pattern maintains strength
        var coherence: Float // Internal consistency of pattern
        
        // Recent changes in pattern structure
        var recentChanges: [StructuralChange]
        
        struct StructuralChange: Hashable, Codable {
            let timestamp: Date
            let changeType: ChangeType
            let impact: Float // Impact on pattern stability (0.0 to 1.0)
            
            enum ChangeType: String, Codable {
                case nodeAddition
                case nodeRemoval
                case connectionStrengthening
                case connectionWeakening
                case patternMerge
                case patternSplit
            }
            
            func hash(into hasher: inout Hasher) {
                hasher.combine(timestamp)
                hasher.combine(changeType)
                hasher.combine(impact)
            }
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(score)
            hasher.combine(volatility)
            hasher.combine(persistence)
            hasher.combine(coherence)
            hasher.combine(recentChanges)
        }
    }
    
    // MARK: - Initialization
    
    init(
        patternType: PatternType,
        confidence: Float,
        involvedNodes: Set<UUID>,
        connections: [NeuralConnection],
        neuralContext: NeuralContext
    ) {
        self.id = UUID()
        self.patternType = patternType
        self.confidence = confidence
        self.involvedNodes = involvedNodes
        self.supportingConnections = connections
        self.neuralContext = neuralContext
        
        // Initialize temporal properties
        self.firstDetected = Date()
        self.lastUpdated = Date()
        self.frequency = 1
        
        // Initialize metrics
        self.growth = GrowthMetrics(
            rate: 0.0,
            acceleration: 0.0,
            sustainedPeriod: 0,
            projectedGrowth: nil,
            growthStage: .emerging
        )
        
        self.stability = StabilityMetrics(
            score: 0.0,
            volatility: 1.0,
            persistence: 0,
            coherence: confidence,
            recentChanges: []
        )
        
        self.significance = confidence
        
        // Initialize metadata
        self.metadata = PatternMetadata(
            createdAt: self.firstDetected,
            lastUpdated: self.lastUpdated,
            frequency: self.frequency,
            stability: 0.0,
            source: .systemInferred(confidence: confidence)
        )
    }
    
    // MARK: - Pattern Management
    
    mutating func updatePattern(
        newConnections: [NeuralConnection],
        confidence: Float,
        timestamp: Date = Date()
    ) {
        // Update basic properties
        self.confidence = confidence
        self.lastUpdated = timestamp
        self.frequency += 1
        
        // Update connections and track changes
        let addedConnections = Set(newConnections).subtracting(Set(supportingConnections))
        let removedConnections = Set(supportingConnections).subtracting(Set(newConnections))
        
        // Record structural changes
        if !addedConnections.isEmpty {
            stability.recentChanges.append(
                StabilityMetrics.StructuralChange(
                    timestamp: timestamp,
                    changeType: .connectionStrengthening,
                    impact: Float(addedConnections.count) / Float(supportingConnections.count)
                )
            )
        }
        
        if !removedConnections.isEmpty {
            stability.recentChanges.append(
                StabilityMetrics.StructuralChange(
                    timestamp: timestamp,
                    changeType: .connectionWeakening,
                    impact: Float(removedConnections.count) / Float(supportingConnections.count)
                )
            )
        }
        
        // Update supporting connections
        self.supportingConnections = newConnections
        
        // Update growth metrics
        updateGrowthMetrics(timestamp: timestamp)
        
        // Update stability metrics
        updateStabilityMetrics()
        
        // Update significance based on new metrics
        updateSignificance()
        
        // Update metadata
        self.metadata.lastUpdated = timestamp
        self.metadata.frequency = self.frequency
        self.metadata.stability = self.stability.score
    }
    
    // MARK: - Private Helper Methods
    private mutating func updateGrowthMetrics(timestamp: Date) {
        let newGrowthRate = calculateGrowthRate()
        let timeSinceFirst = timestamp.timeIntervalSince(firstDetected)
        
        growth.acceleration = newGrowthRate - growth.rate
        growth.rate = newGrowthRate
        growth.sustainedPeriod = timeSinceFirst
        
        // Update growth stage
        growth.growthStage = determineGrowthStage(
            rate: newGrowthRate,
            acceleration: growth.acceleration,
            timeSinceFirst: timeSinceFirst
        )
        
        // Project future growth if pattern is stable enough
        if stability.score > 0.7 {
            growth.projectedGrowth = projectFutureGrowth()
        }
    }
    
    private mutating func updateStabilityMetrics() {
        // Calculate new stability metrics
        let newCoherence = calculatePatternCoherence()
        let newVolatility = calculateVolatility()
        
        stability.coherence = newCoherence
        stability.volatility = newVolatility
        stability.persistence = lastUpdated.timeIntervalSince(firstDetected)
        
        // Update overall stability score
        stability.score = calculateStabilityScore(
            coherence: newCoherence,
            volatility: newVolatility,
            persistence: stability.persistence
        )
        
        // Trim old changes, keeping only recent history
        let recentTimeWindow: TimeInterval = 86400 // 24 hours
        stability.recentChanges = stability.recentChanges.filter {
            abs($0.timestamp.timeIntervalSinceNow) < recentTimeWindow
        }
    }
    
    private func calculateGrowthRate() -> Float {
        // Calculate growth rate based on frequency and connection strengths
        let averageStrength = supportingConnections.reduce(0.0) { $0 + $1.weight } / Float(supportingConnections.count)
        return averageStrength * Float(frequency)
    }
    
    private func calculatePatternCoherence() -> Float {
        // Calculate pattern coherence based on connection structure
        let totalConnections = Float(supportingConnections.count)
        let totalStrength = supportingConnections.reduce(0.0) { $0 + $1.weight }
        return totalStrength / totalConnections
    }
    
    private func calculateVolatility() -> Float {
        // Calculate pattern volatility based on recent changes
        let recentChangesImpact = stability.recentChanges.reduce(0.0) { $0 + $1.impact }
        return recentChangesImpact / Float(max(1, stability.recentChanges.count))
    }
    
    private func calculateStabilityScore(coherence: Float, volatility: Float, persistence: TimeInterval) -> Float {
        // Normalize persistence to a 0-1 scale (considering 7 days as full stability)
        let normalizedPersistence = Float(min(persistence / (7 * 86400), 1.0))
        
        // Combine metrics with weights
        let coherenceWeight: Float = 0.4
        let volatilityWeight: Float = 0.3
        let persistenceWeight: Float = 0.3
        
        return (coherence * coherenceWeight) +
               ((1 - volatility) * volatilityWeight) +
               (normalizedPersistence * persistenceWeight)
    }
    
    private func determineGrowthStage(rate: Float, acceleration: Float, timeSinceFirst: TimeInterval) -> GrowthMetrics.GrowthStage {
        // Determine growth stage based on metrics
        switch (rate, acceleration, timeSinceFirst) {
        case _ where timeSinceFirst < 3600: // First hour
            return .emerging
        case (let r, let a, _) where r > 0.5 && a > 0:
            return .accelerating
        case (let r, let a, _) where r > 0.7 && abs(a) < 0.1:
            return .stabilizing
        case (let r, let a, _) where r > 0.8 && abs(a) < 0.05:
            return .mature
        case (let r, let a, _) where r < 0.5 || a < -0.1:
            return .declining
        default:
            return .stabilizing
        }
    }
    
    private func projectFutureGrowth() -> Float {
        // Project future growth based on current metrics
        let baseGrowth = growth.rate + (growth.acceleration * 0.5)
        let stabilityFactor = stability.score
        
        return baseGrowth * stabilityFactor
    }
    
    private mutating func updateSignificance() {
        // Update overall pattern significance
        self.significance = (
            confidence * 0.3 +
            stability.score * 0.3 +
            Float(frequency) / 100.0 * 0.2 +
            growth.rate * 0.2
        ).clamped(to: 0...1)
    }
}

// MARK: - Helpers

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

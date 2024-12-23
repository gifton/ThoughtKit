//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/21/24.
//

import Foundation
import NaturalLanguage

extension MDResult {
    struct Insight: MetaData {
        let id: UUID
        let value: String
        let confidenceScore: Float
        let sourcePosition: Range<Int>?
        let frequency: Int
        
        // Core insight properties
        let category: InsightCategory
        let type: InsightType
        let depth: InsightDepth
        let impact: InsightImpact
        
        // Temporal aspects
        let discoveredAt: Date
        let validityPeriod: ValidityPeriod?
        let recurrence: RecurrencePattern?
        
        // Relationship mapping
        let connections: InsightConnections
        let context: InsightContext
        let evolution: InsightEvolution
        
        // Analysis metadata
        let validation: InsightValidation
        let qualities: InsightQualities
        let applicationStatus: ApplicationStatus
        
        var nodeType: NodeType { .insight }
        
        // MARK: - Nested Types
        
        enum InsightCategory: String, Codable {
            case selfAwareness     // Understanding of self
            case interpersonal     // Understanding of relationships
            case behavioral        // Patterns in actions
            case emotional        // Emotional patterns
            case cognitive        // Thinking patterns
            case situational      // Context-specific realizations
            case professional     // Work-related insights
            case philosophical    // Deep understanding of life
            case therapeutic      // Mental health related
            case developmental    // Personal growth
            case creative        // Artistic or innovative
            case spiritual       // Spiritual or existential
            
            var priority: Int {
                switch self {
                case .selfAwareness: return 10
                case .interpersonal: return 9
                case .behavioral: return 8
                case .emotional: return 8
                case .cognitive: return 7
                case .situational: return 6
                case .professional: return 6
                case .philosophical: return 5
                case .therapeutic: return 9
                case .developmental: return 7
                case .creative: return 5
                case .spiritual: return 5
                }
            }
        }
        
        enum InsightType: String, Codable {
            case realization      // Sudden understanding
            case pattern         // Recognition of patterns
            case connection      // Linking different ideas
            case learning        // New understanding
            case breakthrough    // Major advancement
            case confirmation    // Validating existing thoughts
            case contradiction   // Challenging beliefs
            case integration     // Combining insights
        }
        
        struct InsightDepth: Codable {
            let level: Level
            let complexity: Float // 0-1
            let abstraction: Float // 0-1
            let uniqueness: Float // 0-1
            
            enum Level: Int, Codable {
                case surface = 1     // Initial observations
                case analytical = 2  // Basic analysis
                case conceptual = 3  // Pattern recognition
                case systemic = 4    // System-level understanding
                case transformative = 5 // Life-changing insights
            }
        }
        
        struct InsightImpact: Codable {
            let scope: Scope
            let immediacy: Immediacy
            let duration: Duration
            let intensity: Float // 0-1
            
            enum Scope: String, Codable {
                case personal
                case interpersonal
                case professional
                case community
                case universal
            }
            
            enum Immediacy: String, Codable {
                case immediate
                case shortTerm
                case longTerm
                case gradual
                case conditional
            }
            
            enum Duration: String, Codable {
                case temporary
                case recurring
                case permanent
                case evolving
            }
        }
        
        struct ValidityPeriod: Codable {
            let start: Date
            let end: Date?
            let confidence: Float
            let constraints: [String]?
        }
        
        struct RecurrencePattern: Codable {
            let frequency: Frequency
            let triggers: [Trigger]
            let consistency: Float
            
            enum Frequency: Codable {
                case daily(times: Int)
                case weekly(days: Set<Int>)
                case monthly(days: Set<Int>)
                case situational(context: String)
            }
            
            enum Trigger: Codable {
                case emotion(String)
                case event(String)
                case context(String)
                case interaction(String)
            }
        }
        
        struct InsightConnections: Codable {
            let relatedInsights: [UUID]
            let supportingEvidence: [Evidence]
            let contradictions: [Contradiction]
            let influences: [Influence]
            
            struct Evidence: Codable {
                let type: EvidenceType
                let source: String
                let strength: Float
                let date: Date
                
                enum EvidenceType: String, Codable {
                    case observation
                    case experience
                    case feedback
                    case data
                    case research
                }
            }
            
            struct Contradiction: Codable {
                let insightId: UUID
                let nature: String
                let resolution: Resolution?
                
                enum Resolution: Codable {
                    case integrated
                    case superseded
                    case contextual
                    case unresolved
                }
            }
            
            struct Influence: Codable {
                let source: String
                let type: InfluenceType
                let strength: Float
                
                enum InfluenceType: String, Codable {
                    case catalyst
                    case inspiration
                    case validation
                    case challenge
                }
            }
        }
        
        struct InsightContext: Codable {
            let emotional: EmotionalContext
            let situational: SituationalContext
            let temporal: TemporalContext
            
            struct EmotionalContext: Codable {
                let dominantEmotion: String
                let intensity: Float
                let stability: Float
            }
            
            struct SituationalContext: Codable {
                let environment: String
                let triggers: [String]
                let constraints: [String]
            }
            
            struct TemporalContext: Codable {
                let timeOfDay: Date
                let duration: TimeInterval
                let frequency: Int
            }
        }
        
        struct InsightEvolution: Codable {
            let stage: Stage
            let maturity: Float
            let revisions: [Revision]
            
            enum Stage: String, Codable {
                case emerging
                case developing
                case stabilizing
                case mature
                case transforming
            }
            
            struct Revision: Codable {
                let date: Date
                let nature: String
                let impact: Float
            }
        }
        
        struct InsightValidation: Codable {
            let status: ValidationStatus
            let method: ValidationMethod
            let confidence: Float
            let lastValidated: Date
            
            enum ValidationStatus: String, Codable {
                case hypothetical
                case observed
                case tested
                case confirmed
                case refuted
            }
            
            enum ValidationMethod: String, Codable {
                case experience
                case observation
                case feedback
                case analysis
                case testing
            }
        }
        
        struct InsightQualities: Codable {
            let clarity: Float
            let actionability: Float
            let relevance: Float
            let reliability: Float
            let innovativeness: Float
        }
        
        enum ApplicationStatus: String, Codable {
            case untried
            case inProgress
            case successful
            case challenging
            case failed
            case adapted
        }
    }
}

// MARK: - Insight Extraction and Analysis

class InsightAnalyzer {
    private let tagger: NLTagger
    private let insightPatterns: [InsightPattern]
    private let languageModel: NLModel?
    
    struct InsightPattern {
        let triggers: [String]
        let category: MDResult.Insight.InsightCategory
        let type: MDResult.Insight.InsightType
        let baseConfidence: Float
    }
    
    init() {
        self.tagger = NLTagger(tagSchemes: [.lexicalClass, .sentimentScore])
        self.insightPatterns = Self.loadInsightPatterns()
        self.languageModel = try? NLModel(contentsOf: .init(string: "")!)
    }
    
    private static func loadInsightPatterns() -> [InsightPattern] {
        // Example patterns - would be loaded from a configuration file
        return [
            InsightPattern(
                triggers: ["I realized", "I understood", "I discovered"],
                category: .selfAwareness,
                type: .realization,
                baseConfidence: 0.8
            ),
            InsightPattern(
                triggers: ["pattern", "always", "never", "repeatedly"],
                category: .behavioral,
                type: .pattern,
                baseConfidence: 0.7
            ),
            InsightPattern(
                triggers: ["connected", "relates to", "links with"],
                category: .cognitive,
                type: .connection,
                baseConfidence: 0.75
            )
        ]
    }
    
    func extractInsights(from text: String) -> [MDResult.Insight] {
        var insights: [MDResult.Insight] = []
        let sentences = text.components(separatedBy: ".").filter { !$0.isEmpty }
        
        for sentence in sentences {
            if let insight = analyzeInsight(in: sentence) {
                insights.append(insight)
            }
        }
        
        // Post-process insights for relationships
        return processInsightRelationships(insights)
    }
    
    private func analyzeInsight(in sentence: String) -> MDResult.Insight? {
        // Basic detection
        guard let (category, type, confidence) = detectInsight(in: sentence) else {
            return nil
        }
        
        // Create insight with rich metadata
        return MDResult.Insight(
            id: UUID(),
            value: sentence.trimmingCharacters(in: .whitespacesAndNewlines),
            confidenceScore: confidence,
            sourcePosition: nil, // Would need to calculate from original text
            frequency: 1,
            category: category,
            type: type,
            depth: analyzeDepth(sentence),
            impact: analyzeImpact(sentence),
            discoveredAt: Date(),
            validityPeriod: nil,
            recurrence: analyzeRecurrence(sentence),
            connections: analyzeConnections(sentence),
            context: analyzeContext(sentence),
            evolution: MDResult.Insight.InsightEvolution(
                stage: .emerging,
                maturity: 0.1,
                revisions: []
            ),
            validation: MDResult.Insight.InsightValidation(
                status: .hypothetical,
                method: .observation,
                confidence: confidence,
                lastValidated: Date()
            ),
            qualities: analyzeQualities(sentence),
            applicationStatus: .untried
        )
    }
    
    private func detectInsight(in text: String) -> (MDResult.Insight.InsightCategory, MDResult.Insight.InsightType, Float)? {
        // Use NLP and patterns to detect insights
        let lowercased = text.lowercased()
        
        for pattern in insightPatterns {
            if pattern.triggers.contains(where: { lowercased.contains($0) }) {
                return (pattern.category, pattern.type, pattern.baseConfidence)
            }
        }
        
        // Use language model as backup
        if let prediction = try? languageModel?.predictedLabel(for: text),
           let category = MDResult.Insight.InsightCategory(rawValue: prediction) {
            return (category, .realization, 0.6)
        }
        
        return nil
    }
    
    // MARK: - Analysis Helper Methods
    
    private func analyzeDepth(_ text: String) -> MDResult.Insight.InsightDepth {
        // Analyze complexity and depth of insight
        // This would involve sophisticated NLP analysis
        return MDResult.Insight.InsightDepth(
            level: .analytical,
            complexity: 0.5,
            abstraction: 0.5,
            uniqueness: 0.5
        )
    }
    
    private func analyzeImpact(_ text: String) -> MDResult.Insight.InsightImpact {
        return MDResult.Insight.InsightImpact(
            scope: .personal,
            immediacy: .immediate,
            duration: .evolving,
            intensity: 0.7
        )
    }
    
    private func analyzeRecurrence(_ text: String) -> MDResult.Insight.RecurrencePattern? {
        // Analyze text for temporal patterns
        return nil
    }
    
    private func analyzeConnections(_ text: String) -> MDResult.Insight.InsightConnections {
        return MDResult.Insight.InsightConnections(
            relatedInsights: [],
            supportingEvidence: [],
            contradictions: [],
            influences: []
        )
    }
    
    private func analyzeContext(_ text: String) -> MDResult.Insight.InsightContext {
        return MDResult.Insight.InsightContext(
            emotional: .init(
                dominantEmotion: "neutral",
                intensity: 0.5,
                stability: 0.5
            ),
            situational: .init(
                environment: "unknown",
                triggers: [],
                constraints: []
            ),
            temporal: .init(
                timeOfDay: Date(),
                duration: 0,
                frequency: 1
            )
        )
    }
    
    private func analyzeQualities(_ text: String) -> MDResult.Insight.InsightQualities {
        return MDResult.Insight.InsightQualities(
            clarity: 0.7,
            actionability: 0.5,
            relevance: 0.8,
            reliability: 0.6,
            innovativeness: 0.5
        )
    }
    
    private func processInsightRelationships(_ insights: [MDResult.Insight]) -> [MDResult.Insight] {
        // Process relationships between insights
        // This would involve semantic analysis and pattern matching
        return insights
    }
}

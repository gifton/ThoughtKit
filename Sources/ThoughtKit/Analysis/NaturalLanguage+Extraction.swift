//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/10/24.
//

import Foundation
import NaturalLanguage

// Result types for different analyses
struct NamedEntity {
    let value: String
    let range: Range<Int>
    let confidence: Float
}

struct SentimentResult {
    let score: Double  // -1.0 to 1.0
    let mainEmotion: String? // Basic inference from score
}

class ContentAnalyzer {
    // MARK: - Built-in NLTagger Capabilities
    
    func extractPeople(from text: String) -> [NamedEntity] {
        return extractNamedEntities(from: text, type: .personalName)
    }
    
    func extractOrganizations(from text: String) -> [NamedEntity] {
        return extractNamedEntities(from: text, type: .organizationName)
    }
    
    func extractLocations(from text: String) -> [NamedEntity] {
        return extractNamedEntities(from: text, type: .placeName)
    }
    
    // doesnt work
    func extractDates(from text: String) -> [NamedEntity] {
        return extractNamedEntities(from: text, type: .particle)
    }
    
    private func extractNamedEntities(from text: String, type: NLTag) -> [NamedEntity] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var entities: [NamedEntity] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .nameType,
                            options: options) { tag, range in
            guard let tag = tag, tag == type else { return true }
            
            let entity = String(text[range])
            let startIndex = text.distance(from: text.startIndex, to: range.lowerBound)
            let endIndex = text.distance(from: text.startIndex, to: range.upperBound)
            
            // Calculate basic confidence based on length and context
            let confidence = calculateConfidence(entity: entity)
            
            entities.append(NamedEntity(
                value: entity,
                range: startIndex..<endIndex,
                confidence: confidence
            ))
            
            return true
        }
        
        return entities
    }
    
    func analyzeSentiment(of text: String) -> SentimentResult {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let (sentiment, _) = tagger.tag(at: text.startIndex,
                                      unit: .paragraph,
                                      scheme: .sentimentScore)
        
        let score = Double(sentiment?.rawValue ?? "0") ?? 0
        
        // Basic emotion inference from sentiment score
        let emotion: String? = {
            switch score {
            case 0.7...1.0: return "Very Positive"
            case 0.3..<0.7: return "Positive"
            case (-0.3)..<0.3: return "Neutral"
            case (-0.7)...(-0.3): return "Negative"
            case -1.0...(-0.7): return "Very Negative"
            default: return nil
            }
        }()
        
        return SentimentResult(score: score, mainEmotion: emotion)
    }
    
    // Helper function to calculate basic confidence scores
    private func calculateConfidence(entity: String) -> Float {
        // Basic heuristic - can be enhanced
        var confidence: Float = 0.5
        
        // Longer entities tend to be more reliable
        confidence += Float(min(entity.count, 10)) / 20.0
        
        // Capitalization suggests proper noun
        if entity.first?.isUppercase == true {
            confidence += 0.2
        }
        
        return min(confidence, 1.0)
    }
    
    // MARK: - Limited or No Direct Support
    
    // topic - Would need custom implementation or ML model
    // category - Would need custom categorization logic
    // emotion - Would need deeper NLP or ML model
    // activity - Would need custom verb phrase extraction
    // summary - Would need custom summarization logic
    
    // Example of how you might implement basic topic detection
    func inferTopics(from text: String) -> [String: Float] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var topics: [String: Int] = [:]
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        // Get noun phrases as potential topics
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .lexicalClass,
                            options: options) { tag, range in
            if let tag = tag, tag == .noun {
                let word = String(text[range]).lowercased()
                topics[word, default: 0] += 1
            }
            return true
        }
        
        // Convert frequencies to scores
        let total = Float(topics.values.reduce(0, +))
        return topics.mapValues { Float($0) / total }
    }
}

// Example usage:
let analyzer = ContentAnalyzer()
let text = """
    Yesterday, John Smith from Apple Inc. visited our office in San Francisco
    to discuss the upcoming product launch event. The meeting was very productive
    and everyone felt excited about the collaboration.
    """

// Extract different types of information
//let people = analyzer.extractPeople(from: text)
//let organizations = analyzer.extractOrganizations(from: text)
//let locations = analyzer.extractLocations(from: text)
//let dates = analyzer.extractDates(from: text)
//let sentiment = analyzer.analyzeSentiment(of: text)
//let topics = analyzer.inferTopics(from: text)

//print("People:", people.map { $0.value })
//print("Organizations:", organizations.map { $0.value })
//print("Locations:", locations.map { $0.value })
//print("Dates:", dates.map { $0.value })
//print("Sentiment:", sentiment.score, sentiment.mainEmotion ?? "Unknown")

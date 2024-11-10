//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/10/24.
//

import Foundation
import NaturalLanguage

class KeywordAnalyzer {
    private var documentCorpus: [(keywords: [String], wordCount: Int)] = []
    private let corpusManager: CorpusManager
    private let minWordLength = 3
    private let maxCompoundWords = 3
    
    // Initialize with optional corpus of existing documents
    init() throws {
            // Initialize corpus manager
            self.corpusManager = try CorpusManager()
            
            // Load existing corpus
            do {
                self.documentCorpus = try corpusManager.loadCorpus()
            } catch {
                print("Error loading corpus: \(error)")
                self.documentCorpus = []
            }
        }
    
    // Main analysis function
    func analyzeKeywords(in text: String) -> [MDResult.Keyword] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = text
        
        var keywords: [String: (frequency: Int, positions: [Range<Int>])] = [:]
        var compoundBuffer: [(String, Range<Int>)] = []
        
        // Options for the tagger
        let options: NLTagger.Options = [
            .omitPunctuation,
            .omitWhitespace,
            .joinNames
        ]
        
        // First pass: Identify potential keywords and their positions
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .lexicalClass,
                            options: options) { tag, tokenRange in
            
            guard let tag = tag else { return true }
            let word = String(text[tokenRange])
            
            // Convert string range to integer range for the struct
            let startIndex = text.distance(from: text.startIndex, to: tokenRange.lowerBound)
            let endIndex = text.distance(from: text.startIndex, to: tokenRange.upperBound)
            let intRange = startIndex..<endIndex
            
            // Process based on lexical class
            switch tag {
            case .noun, .verb, .adjective:
                if word.count >= minWordLength {
                    // Handle compound keywords
                    compoundBuffer.append((word, intRange))
                    if compoundBuffer.count > maxCompoundWords {
                        compoundBuffer.removeFirst()
                    }
                    
                    // Add individual word
                    if keywords[word] == nil {
                        keywords[word] = (1, [intRange])
                    } else {
                        keywords[word]?.frequency += 1
                        keywords[word]?.positions.append(intRange)
                    }
                    
                    // Process compound keywords
                    if compoundBuffer.count >= 2 {
                        let compounds = generateCompounds(from: compoundBuffer)
                        for compound in compounds {
                            if keywords[compound.0] == nil {
                                keywords[compound.0] = (1, [compound.1])
                            } else {
                                keywords[compound.0]?.frequency += 1
                                keywords[compound.0]?.positions.append(compound.1)
                            }
                        }
                    }
                }
            default:
                compoundBuffer.removeAll()
            }
            return true
        }
        
        // Calculate TF-IDF scores
        return keywords.map { keyword, data in
            let tfIdfScore = calculateTfIdf(
                term: keyword,
                frequency: Float(data.frequency),
                documentLength: Float(text.split(separator: " ").count),
                text: text
            )
            
            return .init(
                value: keyword,
                confidenceScore: calculateConfidence(frequency: data.frequency, tfIdf: tfIdfScore),
                sourcePosition: data.positions.first,
                frequency: data.frequency,
                importance: tfIdfScore,
                isCompound: keyword.contains(" ")
            )
        }.sorted { $0.importance > $1.importance }
    }
    
    // Generate compound keywords from buffer
    private func generateCompounds(from buffer: [(String, Range<Int>)]) -> [(String, Range<Int>)] {
        var compounds: [(String, Range<Int>)] = []
        
        for i in 0..<buffer.count-1 {
            var compound = ""
            let startPosition = buffer[i].1.lowerBound
            let endPosition = buffer.last!.1.upperBound
            
            for j in i..<buffer.count {
                if !compound.isEmpty {
                    compound += " "
                }
                compound += buffer[j].0
            }
            
            compounds.append((compound, startPosition..<endPosition))
        }
        
        return compounds
    }
    
    // Calculate TF-IDF score
    private func calculateTfIdf(term: String, frequency: Float, documentLength: Float) -> Float {
            let tf = frequency / documentLength
            
            var documentsWithTerm = 1
            for document in documentCorpus {
                if document.keywords.contains(term) {
                    documentsWithTerm += 1
                }
            }
            
            let idf = log(Float(documentCorpus.count + 1) / Float(documentsWithTerm))
            return tf * idf
        }
        
    
    // Calculate confidence score based on frequency and importance
    private func calculateConfidence(frequency: Int, tfIdf: Float) -> Float {
        let frequencyWeight: Float = 0.3
        let tfIdfWeight: Float = 0.7
        
        let normalizedFrequency = min(Float(frequency) / 10.0, 1.0)  // Normalize frequency to 0-1
        return (normalizedFrequency * frequencyWeight) + (min(tfIdf, 1.0) * tfIdfWeight)
    }
    
    // Add a document to the corpus for better TF-IDF calculations
    func addToCorpus(_ text: String) {
        do {
            try corpusManager.addDocument(text)
            // Reload corpus after adding new document
            self.documentCorpus = try corpusManager.loadCorpus()
        } catch {
            print("Error adding to corpus: \(error)")
        }
    }
}

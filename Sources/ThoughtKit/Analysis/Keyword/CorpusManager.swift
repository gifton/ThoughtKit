//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/10/24.
//

import Foundation
import NaturalLanguage

struct CorpusDocument: Codable {
    let id: String
    let keywords: [String]  // Only store keywords instead of full text
    let dateAdded: Date
    let wordCount: Int      // Store for TF-IDF calculations
}

class CorpusManager {
    private let fileManager = FileManager.default
    private let corpusURL: URL
    
    init() throws {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CorpusError.documentsDirectoryNotFound
        }
        corpusURL = documentsDirectory.appendingPathComponent("keyword_corpus")
        
        if !fileManager.fileExists(atPath: corpusURL.path) {
            try fileManager.createDirectory(at: corpusURL, withIntermediateDirectories: true)
        }
    }
    
    // Extract keywords from text before storing
    func addDocument(_ text: String) throws {
        let keywords = extractKeywords(from: text)
        let documentId = UUID().uuidString
        let document = CorpusDocument(
            id: documentId,
            keywords: keywords,
            dateAdded: Date(),
            wordCount: text.split(separator: " ").count
        )
        
        let documentURL = corpusURL.appendingPathComponent("\(documentId).json")
        let encoder = JSONEncoder()
        let data = try encoder.encode(document)
        try data.write(to: documentURL)
    }
    
    // Helper method to extract keywords
    private func extractKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var keywords: Set<String> = []  // Use Set to avoid duplicates
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .lexicalClass,
                            options: [.omitPunctuation, .omitWhitespace]) { tag, range in
            if let tag = tag,
               (tag == .noun || tag == .verb || tag == .adjective) {
                let word = String(text[range]).lowercased()
                if word.count >= 3 {  // Filter out very short words
                    keywords.insert(word)
                }
            }
            return true
        }
        
        return Array(keywords)
    }
    
    // Load corpus for TF-IDF calculations
    func loadCorpus() throws -> [(keywords: [String], wordCount: Int)] {
        let documentURLs = try fileManager.contentsOfDirectory(
            at: corpusURL,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }
        
        return try documentURLs.map { url in
            let data = try Data(contentsOf: url)
            let document = try JSONDecoder().decode(CorpusDocument.self, from: data)
            return (keywords: document.keywords, wordCount: document.wordCount)
        }
    }
}


enum CorpusError: Error {
    case documentsDirectoryNotFound
}

// Example usage:
//do {
//    let analyzer = try KeywordAnalyzer()
//    
//    // Add new document
//    analyzer.addToCorpus("Machine learning models are transforming the technology landscape.")
//    
//    // Analyze new text
//    let text = "Artificial intelligence and machine learning are revolutionizing technology."
//    let keywords = analyzer.analyzeKeywords(in: text)
//} catch {
//    print("Error: \(error)")
//}

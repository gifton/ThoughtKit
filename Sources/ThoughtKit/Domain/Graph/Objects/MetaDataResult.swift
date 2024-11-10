//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/9/24.
//

import Foundation

typealias MDResult = MetaDataResult
struct MetaDataResult {
    typealias creator = (NodeType) async throws -> ([MetaData])
    var keywords: [Keyword] = []
    var topics: [Topic] = []
    var emotions: [Emotion] = []
    var locations: [Location] = []
    var activities: [Activity] = []
    var persons: [Person] = []
    var summary: Summary?
    
    static func factory(factory: creator) async throws -> MDResult {
        var new = MetaDataResult()
        new.keywords = (try await factory(.keyword) as? [MDResult.Keyword]) ?? []
        new.topics = (try await factory(.topic) as? [MDResult.Topic]) ?? []
        new.emotions = (try await factory(.emotion) as? [MDResult.Emotion]) ?? []
        new.locations = (try await factory(.location) as? [MDResult.Location]) ?? []
        new.activities = (try await factory(.activity) as? [MDResult.Activity]) ?? []
        new.persons = (try await factory(.person) as? [MDResult.Person]) ?? []
        new.summary = ((try await factory(.summary) as? [MDResult.Summary] ?? [])).first
        
        return new
    }
    
}

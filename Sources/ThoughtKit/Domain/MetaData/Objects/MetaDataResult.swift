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
    var timeReferences: [TimeReference] = []
    var relationships: [HumanRelationship] = []
    var goals: [Goal] = []
    var decisions: [Decision] = []
    var challenges: [Challenge] = []
    var insights: [Insight] = []
    var resources: [Resource] = []
    
    static func factory(factory: creator) async throws -> MDResult {
        var new = MetaDataResult()
        new.keywords = (try await factory(.keyword) as? [MDResult.Keyword]) ?? []
        new.topics = (try await factory(.topic) as? [MDResult.Topic]) ?? []
        new.emotions = (try await factory(.emotion) as? [MDResult.Emotion]) ?? []
        new.locations = (try await factory(.location) as? [MDResult.Location]) ?? []
        new.activities = (try await factory(.activity) as? [MDResult.Activity]) ?? []
        new.persons = (try await factory(.person) as? [MDResult.Person]) ?? []
        new.summary = ((try await factory(.summary) as? [MDResult.Summary] ?? [])).first
        new.timeReferences = ((try await factory(.timeReference) as? [MDResult.TimeReference] ?? []))
        new.relationships = ((try await factory(.humanRelationship) as? [MDResult.HumanRelationship] ?? []))
        new.goals = ((try await factory(.goal) as? [MDResult.Goal] ?? []))
        new.decisions = ((try await factory(.decision) as? [MDResult.Decision] ?? []))
        new.challenges = ((try await factory(.challenge) as? [MDResult.Challenge] ?? []))
        new.insights = ((try await factory(.insight) as? [MDResult.Insight] ?? []))
        new.resources = ((try await factory(.resource) as? [MDResult.Resource] ?? []))
        
        return new
    }
    
}

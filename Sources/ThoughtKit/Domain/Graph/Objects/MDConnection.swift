//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/3/24.
//

import Foundation


/// Defines the structure for connections between nodes in the metadata network.
/// Connections are the edges in our graph structure and represent relationships
/// between nodes (e.g., a thought "has" a keyword, or two thoughts are "related").
/// Each connection has a direction (source → target) and a weight to represent
/// the strength of the relationship.
protocol Connection: Identifiable, Hashable {
    var id: UUID { get }
    var sourceId: UUID { get }
    var targetId: UUID { get }
    var type: MDRelationType { get }
    var weight: Float { get }
}

/// Concrete implementation of a Connection that represents relationships between nodes.
/// This structure maintains information about a single edge in the network,
/// including its strength and usage patterns over time.
struct MetadataConnection: Connection, Codable {
    var id: UUID
    var sourceId: UUID
    var targetId: UUID
    var type: MDRelationType  // Changed from ConnectionType
    var weight: Float
    var createdAt: Date
    var lastAccessed: Date
    var occurrences: Int = 1
    
    // New: Additional metadata about the relationship
    var confidence: Float = 1.0     // How confident we are in this relationship
    var metadata: [String: String]? // Additional relationship properties
}

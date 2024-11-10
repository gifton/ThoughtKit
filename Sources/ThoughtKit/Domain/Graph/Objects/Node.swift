//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/3/24.
//

import Foundation

/// Defines the basic structure for any node in the metadata network.
/// Nodes are the vertices in our graph structure and can represent thoughts,
/// keywords, topics, or any other metadata type that we want to track relationships between.
/// All nodes must be uniquely identifiable and support equality comparison.
protocol Node: Identifiable, Hashable {
    var id: UUID { get }
    var type: NodeType { get }
    var connections: Set<MetadataConnection> { get set }  // Made concrete type
}

/// Defines the different types of nodes that can exist in the network.
/// This enum helps categorize nodes and enables type-specific querying.
/// For example, we can find all keyword nodes or all topic nodes.
enum NodeType: String, Codable, Hashable {
    case thought    // Reference to Core Data thought
    case keyword
    case topic
    case sentiment
    case location
    case person
    case date
    case organization
    case event
    case category
    case emotion
    case activity
    case summary
}

/// Concrete implementation of a Node that stores metadata about thoughts and their relationships.
/// This structure maintains information about a single node in the network, including
/// its relationships with other nodes and usage statistics.
struct MetadataNode: Node, Codable {
    let id: UUID
    let type: NodeType
    let value: String
    var connections: Set<MetadataConnection>
    let createdAt: Date
    
    // Additional metadata
    var frequency: Int = 1
    var lastUsed: Date
    var statistics: [String: Double]? = nil  // Changed to concrete type for Codable
    
    // Hashable implementation
    static func == (lhs: MetadataNode, rhs: MetadataNode) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
 

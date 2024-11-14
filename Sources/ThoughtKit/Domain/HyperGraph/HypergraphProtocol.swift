//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation


/// Defines the hypergraph component interface
protocol HypergraphProtocol: Actor {
    associatedtype EdgeID: Hashable
    
    /// Edge management
    func createEdge(nodes: Set<UUID>, type: MetadataRelationType) async throws -> EdgeID
    func updateEdge(_ id: EdgeID, newNodes: Set<UUID>) async throws
    func removeEdge(_ id: EdgeID) async throws
    
    /// Node management
    func addNodeToEdge(_ nodeId: UUID, edgeId: EdgeID) async throws
    func removeNodeFromEdge(_ nodeId: UUID, edgeId: EdgeID) async throws
    func getEdgesForNode(_ nodeId: UUID) async throws -> Set<EdgeID>
    
    /// Query and analysis
    func findConnected(
        to nodeId: UUID,
        types: Set<NodeType>,
        context: QueryContext
    ) async throws -> [HypergraphMatch]
    
    func findClusters() async throws -> [HypergraphCluster]
    func getActiveEdges() async throws -> Set<EdgeID>
    
    /// Context and metadata
    func setEdgeContext(_ id: EdgeID, context: EdgeContext) async throws
    func getEdgeContext(_ id: EdgeID) async throws -> EdgeContext
}

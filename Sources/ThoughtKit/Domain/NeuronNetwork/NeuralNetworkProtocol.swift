//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation
/// Defines the neural network component interface
protocol NeuralNetworkProtocol: Actor {
    associatedtype NeuronID: Hashable
    associatedtype PatternType: Hashable
    
    /// Core neuron management
    func createNeuron(forType: NodeType?) async throws -> NeuronID
    func updateNeuron(_ id: NeuronID, pattern: PatternType) async throws
    func removeNeuron(_ id: NeuronID) async throws
    
    /// Pattern processing
    func processContent(type: NodeType, content: Any) async throws -> Set<NeuronID>
    func findSimilarPatterns(forNode: UUID, types: Set<NodeType>) async throws -> [NeuralMatch]
    func getPatternStrength(between first: NeuronID, and second: NeuronID) async throws -> Float
    
    /// Learning and adaptation
    func reinforcePattern(_ pattern: PatternType) async throws
    func weakenPattern(_ pattern: PatternType) async throws
    func adaptThresholds() async throws
    
    /// Analysis and insights
    func getEmergingPatterns() async throws -> [EmergingPattern]
    func getActiveNeurons() async throws -> Set<NeuronID>
    func getNeuronConnections(_ id: NeuronID) async throws -> [NeuralConnection]
}

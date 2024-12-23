//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation
struct NeuralConnection: Hashable {
    let sourceId: UUID
    let targetId: UUID
    var weight: Float
    var type: MDRelationType
    var metadata: ConnectionMetadata
}

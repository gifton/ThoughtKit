//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

enum InsightSource {
    case neural(confidence: Float)
    case graph(relations: Set<MetadataRelationType>)
    case hyper(edges: Set<UUID>)
    case combined(sources: [InsightSource])
}

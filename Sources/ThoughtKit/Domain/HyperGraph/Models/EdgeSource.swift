//
//  File.swift
//
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

enum EdgeSource {
    case explicit(userGenerated: Bool)
    case neural(confidence: Float)
    case derived(method: String)
    case hybrid(sources: Set<EdgeSource>)
}

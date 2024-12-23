//
//  File.swift
//
//
//  Created by Gifton Okoronkwo on 11/13/24.
//

import Foundation

enum EdgeSource: Hashable {
    case explicit(userGenerated: Bool)
    case neural(confidence: Float)
    case derived(method: String)
    indirect case hybrid(sources: Set<EdgeSource>)
}

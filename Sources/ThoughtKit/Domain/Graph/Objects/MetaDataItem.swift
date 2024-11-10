//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/9/24.
//

import Foundation


typealias MDItem = MetadataItem
protocol MetadataItem {
    var value: String { get }
    var confidenceScore: Float { get }  // 0.0 to 1.0
    var sourcePosition: Range<Int>? { get }  // Character position in original text
    var frequency: Int { get }  // Number of occurrences in the text
    var nodeType: NodeType { get }
}




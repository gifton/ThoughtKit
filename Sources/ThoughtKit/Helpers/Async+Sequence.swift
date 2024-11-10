//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/9/24.
//

import Foundation

extension Sequence {
    /// Asynchronously performs the given operation on each element in the sequence.
    /// - Parameter operation: An async operation to perform on each element in the sequence.
    func asyncForEach(_ operation: @escaping (Element) async throws -> Void) async throws {
        for element in self {
            try await operation(element)
        }
    }
    
    /// Asynchronously performs the given operation on each element in the sequence concurrently.
    /// - Parameter operation: An async operation to perform on each element in the sequence.
    func asyncConcurrentForEach(_ operation: @escaping (Element) async throws -> Void) async throws {
        // Create array of async operations
        let tasks = map { element in
            Task {
                try await operation(element)
            }
        }
        
        // Wait for all operations to complete and collect potential errors
        for task in tasks {
            try await task.value
        }
    }
    
    /// Asynchronously transforms each element in the sequence using the given operation.
    /// - Parameter transform: An async operation that transforms an element into another type.
    /// - Returns: An array containing the transformed elements.
    func asyncMap<T>(_ transform: @escaping (Element) async throws -> T) async throws -> [T] {
        var results: [T] = []
        
        for element in self {
            try await results.append(transform(element))
        }
        
        return results
    }
    
    /// Asynchronously transforms each element in the sequence concurrently using the given operation.
    /// - Parameter transform: An async operation that transforms an element into another type.
    /// - Returns: An array containing the transformed elements in their original order.
    func asyncConcurrentMap<T>(_ transform: @escaping (Element) async throws -> T) async throws -> [T] {
        let tasks = map { element in
            Task {
                try await transform(element)
            }
        }
        
        return try await tasks.asyncMap { task in
            try await task.value
        }
    }
}

// Optional: Extension specifically for handling operations with a completion percentage
extension Sequence {
    /// Asynchronously performs the given operation on each element in the sequence,
    /// reporting progress through the progressHandler.
    /// - Parameters:
    ///   - operation: An async operation to perform on each element.
    ///   - progressHandler: A closure that receives the current progress (0.0 to 1.0).
    func asyncForEach(
        _ operation: @escaping (Element) async throws -> Void,
        progress progressHandler: @escaping (Double) -> Void
    ) async throws {
        let total = Double(Array(self).count)
        var completed = 0.0
        
        for element in self {
            try await operation(element)
            completed += 1
            progressHandler(completed / total)
        }
    }
}

// Example usage:
enum ExampleUsage {
    static func demonstrate() async throws {
        let items = ["item1", "item2", "item3"]
        
        // Basic async iteration
        try await items.asyncForEach { item in
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate work
            print("Processed \(item)")
        }
        
        // Concurrent async iteration
        try await items.asyncConcurrentForEach { item in
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate work
            print("Processed \(item) concurrently")
        }
        
        // Async mapping
        let transformedItems = try await items.asyncMap { item in
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate work
            return "Transformed \(item)"
        }
        
        // Concurrent async mapping
        let concurrentTransformed = try await items.asyncConcurrentMap { item in
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate work
            return "Transformed \(item) concurrently"
        }
        
        // With progress reporting
        try await items.asyncForEach({ item in
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate work
            print("Processed \(item)")
        }, progress: { progress in
            print("Progress: \(Int(progress * 100))%")
        })
    }
}

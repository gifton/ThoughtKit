//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/21/24.
//

import Foundation

/// A more robust contextual metadata system
public struct ContextualMetadata: Codable {
    // MARK: - Value Types
    public enum Value: Codable, Equatable {
        case string(String)
        case int(Int)
        case double(Double)
        case bool(Bool)
        case date(Date)
        case array([Value])
        case dictionary([String: Value])
        case null
        
        // Custom coding keys for type identification
        private enum CodingKeys: String, CodingKey {
            case type, value
        }
        
        // Type identifier for encoding/decoding
        private enum ValueType: String, Codable {
            case string, int, double, bool, date, array, dictionary, null
        }
        
        // MARK: - Encoding
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .string(let value):
                try container.encode(ValueType.string, forKey: .type)
                try container.encode(value, forKey: .value)
            case .int(let value):
                try container.encode(ValueType.int, forKey: .type)
                try container.encode(value, forKey: .value)
            case .double(let value):
                try container.encode(ValueType.double, forKey: .type)
                try container.encode(value, forKey: .value)
            case .bool(let value):
                try container.encode(ValueType.bool, forKey: .type)
                try container.encode(value, forKey: .value)
            case .date(let value):
                try container.encode(ValueType.date, forKey: .type)
                try container.encode(value.timeIntervalSince1970, forKey: .value)
            case .array(let value):
                try container.encode(ValueType.array, forKey: .type)
                try container.encode(value, forKey: .value)
            case .dictionary(let value):
                try container.encode(ValueType.dictionary, forKey: .type)
                try container.encode(value, forKey: .value)
            case .null:
                try container.encode(ValueType.null, forKey: .type)
            }
        }
        
        // MARK: - Decoding
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(ValueType.self, forKey: .type)
            
            switch type {
            case .string:
                self = .string(try container.decode(String.self, forKey: .value))
            case .int:
                self = .int(try container.decode(Int.self, forKey: .value))
            case .double:
                self = .double(try container.decode(Double.self, forKey: .value))
            case .bool:
                self = .bool(try container.decode(Bool.self, forKey: .value))
            case .date:
                let timeInterval = try container.decode(TimeInterval.self, forKey: .value)
                self = .date(Date(timeIntervalSince1970: timeInterval))
            case .array:
                self = .array(try container.decode([Value].self, forKey: .value))
            case .dictionary:
                self = .dictionary(try container.decode([String: Value].self, forKey: .value))
            case .null:
                self = .null
            }
        }
    }
    
    // MARK: - Properties
    
    private var storage: [String: Value]
    
    // MARK: - Initialization
    
    init() {
        self.storage = [:]
    }
    
    // MARK: - Subscript Access
    
    subscript(key: String) -> Value? {
        get { storage[key] }
        set { storage[key] = newValue }
    }
    
    // MARK: - Type-Safe Accessors
    
    func string(_ key: String) -> String? {
        guard case .string(let value) = storage[key] else { return nil }
        return value
    }
    
    func int(_ key: String) -> Int? {
        guard case .int(let value) = storage[key] else { return nil }
        return value
    }
    
    func double(_ key: String) -> Double? {
        guard case .double(let value) = storage[key] else { return nil }
        return value
    }
    
    func bool(_ key: String) -> Bool? {
        guard case .bool(let value) = storage[key] else { return nil }
        return value
    }
    
    func date(_ key: String) -> Date? {
        guard case .date(let value) = storage[key] else { return nil }
        return value
    }
    
    func array(_ key: String) -> [Value]? {
        guard case .array(let value) = storage[key] else { return nil }
        return value
    }
    
    func dictionary(_ key: String) -> [String: Value]? {
        guard case .dictionary(let value) = storage[key] else { return nil }
        return value
    }
    
    // MARK: - Type-Safe Setters
    
    mutating func set(_ value: String, for key: String) {
        storage[key] = .string(value)
    }
    
    mutating func set(_ value: Int, for key: String) {
        storage[key] = .int(value)
    }
    
    mutating func set(_ value: Double, for key: String) {
        storage[key] = .double(value)
    }
    
    mutating func set(_ value: Bool, for key: String) {
        storage[key] = .bool(value)
    }
    
    mutating func set(_ value: Date, for key: String) {
        storage[key] = .date(value)
    }
    
    mutating func set(_ value: [Value], for key: String) {
        storage[key] = .array(value)
    }
    
    mutating func set(_ value: [String: Value], for key: String) {
        storage[key] = .dictionary(value)
    }
    
    mutating func setNull(for key: String) {
        storage[key] = .null
    }
    
    // MARK: - Removal
    
    @discardableResult
    mutating func removeValue(forKey key: String) -> Value? {
        storage.removeValue(forKey: key)
    }
    
    // MARK: - Utility Methods
    
    func contains(_ key: String) -> Bool {
        storage.keys.contains(key)
    }
    
    var keys: Set<String> {
        Set(storage.keys)
    }
    
    var isEmpty: Bool {
        storage.isEmpty
    }
    
    func merge(_ other: ContextualMetadata) -> ContextualMetadata {
        var result = self
        result.storage.merge(other.storage) { current, _ in current }
        return result
    }
}

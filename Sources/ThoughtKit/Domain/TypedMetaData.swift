//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/17/24.
//

import Foundation

public struct TypedMetadata: Hashable, Codable {
    private var stringValues: [String: String] = [:]
    private var intValues: [String: Int] = [:]
    private var dateValues: [String: Date] = [:]
    private var doubleValues: [String: Double] = [:]
    
    public init(stringValues: [String : String] = [:], intValues: [String : Int] = [:], dateValues: [String : Date] = [:], doubleValues: [String : Double] = [:]) {
        self.stringValues = stringValues
        self.intValues = intValues
        self.dateValues = dateValues
        self.doubleValues = doubleValues
    }
    
    var isEmpty: Bool {
        stringValues.isEmpty && intValues.isEmpty &&
        dateValues.isEmpty && doubleValues.isEmpty
    }
    
    // Type-safe retrieval
    func getString(_ key: String) -> String? {
        stringValues[key]
    }
    
    func getInt(_ key: String) -> Int? {
        intValues[key]
    }
    
    func getDate(_ key: String) -> Date? {
        dateValues[key]
    }
    
    func getDouble(_ key: String) -> Double? {
        doubleValues[key]
    }
    
    // Type-specific operations become possible
    mutating func incrementInt(_ key: String, by value: Int = 1) {
        if let current = intValues[key] {
            intValues[key] = current + value
        }
    }
    
    // Easier to work with collections of specific types
    var allStrings: [String] {
        Array(stringValues.values)
    }
    
    var allInts: [Int] {
        Array(intValues.values)
    }
    
    
    mutating func remove<T>(_ key: String, type: T.Type) {
        switch type {
        case is String.Type:
            stringValues.removeValue(forKey: key)
        case is Int.Type:
            intValues.removeValue(forKey: key)
        case is Date.Type:
            dateValues.removeValue(forKey: key)
        case is Double.Type:
            doubleValues.removeValue(forKey: key)
        default:
            fatalError("Unsupported type: \(type)")
        }
    }
}

extension TypedMetadata {
    subscript<T>(key: String, as type: T.Type) -> T? {
        get {
            self[key] as? T
        }
        set {
            self[key] = newValue
        }
    }
    
    subscript(key: String) -> Any? {
        get {
            // Check each dictionary and return the first non-nil value
            if let value = stringValues[key] { return value }
            if let value = intValues[key] { return value }
            if let value = dateValues[key] { return value }
            if let value = doubleValues[key] { return value }
            return nil
        }
        
        set {
            // Remove existing value if setting to nil
            if newValue == nil {
                stringValues.removeValue(forKey: key)
                intValues.removeValue(forKey: key)
                dateValues.removeValue(forKey: key)
                doubleValues.removeValue(forKey: key)
                return
            }
            
            // Set the value based on its type
            switch newValue {
            case let string as String:
                stringValues[key] = string
                // Clear other type dictionaries for this key
                intValues.removeValue(forKey: key)
                dateValues.removeValue(forKey: key)
                doubleValues.removeValue(forKey: key)
                
            case let int as Int:
                intValues[key] = int
                // Clear other type dictionaries for this key
                stringValues.removeValue(forKey: key)
                dateValues.removeValue(forKey: key)
                doubleValues.removeValue(forKey: key)
                
            case let date as Date:
                dateValues[key] = date
                // Clear other type dictionaries for this key
                stringValues.removeValue(forKey: key)
                intValues.removeValue(forKey: key)
                doubleValues.removeValue(forKey: key)
                
            case let double as Double:
                doubleValues[key] = double
                // Clear other type dictionaries for this key
                stringValues.removeValue(forKey: key)
                intValues.removeValue(forKey: key)
                dateValues.removeValue(forKey: key)
                
            default:
                fatalError("Unsupported type: \(type(of: newValue))")
            }
        }
    }
}

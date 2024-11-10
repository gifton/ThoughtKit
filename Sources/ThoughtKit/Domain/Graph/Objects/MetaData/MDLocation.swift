//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 11/9/24.
//

import Foundation

extension MDResult { 
    // Location metadata
    struct Location: MDItem {
        let value: String
        let confidenceScore: Float
        let sourcePosition: Range<Int>?
        let frequency: Int
        let coordinates: (latitude: Double, longitude: Double)?
        let locationType: LocationType
        let precision: Int  // Geographical precision level (1-10)
        
        // Additional computed property
        var requiresCoordinates: Bool {
            return locationType.requiresCoordinates
        }
        
        var nodeType: NodeType { .location }
    }
    
    enum LocationType: String, CaseIterable {
        // Administrative Divisions
        case country
        case state
        case province
        case city
        case district
        case neighborhood
        case postalCode
        
        // Natural Features
        case mountain
        case river
        case lake
        case ocean
        case forest
        case desert
        case valley
        case beach
        case island
        
        // Human-Made Locations
        case building
        case landmark
        case monument
        case park
        case airport
        case station
        case port
        case road
        case bridge
        
        // Commercial/Social
        case restaurant
        case hotel
        case store
        case mall
        case office
        case school
        case hospital
        case museum
        case theater
        
        // Generic
        case point         // Specific coordinate point
        case area         // General area or region
        case route        // Path or journey
        case intersection // Junction of two or more paths
        case address      // Street address
        
        // Virtual/Online
        case virtual      // Virtual or online location
        case hybrid       // Physical location with significant online presence
        
        // Special
        case historical   // Historical site or location that may no longer exist
        case fictional    // Locations from literature, movies, or other media
        case temporary    // Pop-up locations, temporary venues
        case unknown      // When type cannot be determined
        
        var isAdministrative: Bool {
            switch self {
            case .country, .state, .province, .city, .district, .neighborhood, .postalCode:
                return true
            default:
                return false
            }
        }
        
        var isNatural: Bool {
            switch self {
            case .mountain, .river, .lake, .ocean, .forest, .desert, .valley, .beach, .island:
                return true
            default:
                return false
            }
        }
        
        var isCommercial: Bool {
            switch self {
            case .restaurant, .hotel, .store, .mall, .office:
                return true
            default:
                return false
            }
        }
        
        var requiresCoordinates: Bool {
            switch self {
            case .point, .address, .building, .landmark:
                return true
            default:
                return false
            }
        }
    }
}

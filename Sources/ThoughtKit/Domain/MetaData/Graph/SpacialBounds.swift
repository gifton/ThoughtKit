//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/23/24.
//

import Foundation

struct SpatialBounds: Hashable, Codable {
    // MARK: - Core Properties
    let center: Coordinate
    let radius: Double // In meters
    var shape: BoundaryShape
    
    // MARK: - Optional Constraints
    var altitude: ClosedRange<Double>? // In meters
    var timeRange: ClosedRange<Date>?
    var accuracy: Double // In meters
    
    struct Coordinate: Hashable, Codable {
        let latitude: Double
        let longitude: Double
        
        func distance(to other: Coordinate) -> Double {
            // Haversine formula for calculating great-circle distance
            let R = 6371000.0 // Earth's radius in meters
            
            let φ1 = latitude * .pi / 180
            let φ2 = other.latitude * .pi / 180
            let Δφ = (other.latitude - latitude) * .pi / 180
            let Δλ = (other.longitude - longitude) * .pi / 180
            
            let a = sin(Δφ/2) * sin(Δφ/2) +
                   cos(φ1) * cos(φ2) *
                   sin(Δλ/2) * sin(Δλ/2)
            let c = 2 * atan2(sqrt(a), sqrt(1-a))
            
            return R * c
        }
    }
    
    enum BoundaryShape: Hashable, Codable {
        case circle
        case polygon(vertices: [Coordinate])
        case rectangle(northEast: Coordinate, southWest: Coordinate)
        
        func area(radius: Double) -> Double {
            switch self {
            case .circle:
                return .pi * pow(radius, 2)
            case .polygon(let vertices):
                return calculatePolygonArea(vertices)
            case .rectangle(let ne, let sw):
                return abs((ne.longitude - sw.longitude) * (ne.latitude - sw.latitude))
            }
        }
        
        private func calculatePolygonArea(_ vertices: [Coordinate]) -> Double {
            // Shoelace formula for polygon area
            guard vertices.count > 2 else { return 0 }
            
            var area = 0.0
            for i in 0..<vertices.count {
                let j = (i + 1) % vertices.count
                area += vertices[i].longitude * vertices[j].latitude
                area -= vertices[j].longitude * vertices[i].latitude
            }
            
            return abs(area) / 2.0
        }
    }
    
    // MARK: - Query Methods
    
    func contains(_ coordinate: Coordinate) -> Bool {
        switch shape {
        case .circle:
            return center.distance(to: coordinate) <= radius
            
        case .polygon(let vertices):
            return isPointInPolygon(coordinate, vertices: vertices)
            
        case .rectangle(let ne, let sw):
            return coordinate.latitude <= ne.latitude &&
                   coordinate.latitude >= sw.latitude &&
                   coordinate.longitude <= ne.longitude &&
                   coordinate.longitude >= sw.longitude
        }
    }
    
    private func isPointInPolygon(_ point: Coordinate, vertices: [Coordinate]) -> Bool {
        // Ray casting algorithm for point-in-polygon test
        var inside = false
        var j = vertices.count - 1
        
        for i in 0..<vertices.count {
            if ((vertices[i].latitude > point.latitude) != (vertices[j].latitude > point.latitude)) &&
                (point.longitude < (vertices[j].longitude - vertices[i].longitude) *
                 (point.latitude - vertices[i].latitude) /
                 (vertices[j].latitude - vertices[i].latitude) + vertices[i].longitude) {
                inside.toggle()
            }
            j = i
        }
        
        return inside
    }
    
    // MARK: - Initialization
    
    init(center: Coordinate, radius: Double, shape: BoundaryShape = .circle) {
        self.center = center
        self.radius = radius
        self.shape = shape
        self.accuracy = 10.0 // Default 10m accuracy
    }
    
    static func circle(center: Coordinate, radius: Double) -> SpatialBounds {
        SpatialBounds(center: center, radius: radius, shape: .circle)
    }
    
    static func polygon(vertices: [Coordinate]) -> SpatialBounds {
        // Calculate center point as average of vertices
        let centerLat = vertices.map { $0.latitude }.reduce(0, +) / Double(vertices.count)
        let centerLon = vertices.map { $0.longitude }.reduce(0, +) / Double(vertices.count)
        let center = Coordinate(latitude: centerLat, longitude: centerLon)
        
        // Calculate radius as maximum distance from center to any vertex
        let radius = vertices.map { center.distance(to: $0) }.max() ?? 0
        
        return SpatialBounds(center: center, radius: radius, shape: .polygon(vertices: vertices))
    }
    
    static func rectangle(northEast: Coordinate, southWest: Coordinate) -> SpatialBounds {
        let centerLat = (northEast.latitude + southWest.latitude) / 2
        let centerLon = (northEast.longitude + southWest.longitude) / 2
        let center = Coordinate(latitude: centerLat, longitude: centerLon)
        
        // Radius as distance to corner
        let radius = center.distance(to: northEast)
        
        return SpatialBounds(center: center, radius: radius, shape: .rectangle(northEast: northEast, southWest: southWest))
    }
}

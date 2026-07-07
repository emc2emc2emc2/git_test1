import CoreLocation
import Foundation

struct LocationPoint: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let altitude: Double
    let speed: Double          // m/s, clamped to >= 0
    let horizontalAccuracy: Double
    let timestamp: Date

    var mode: MovementMode { MovementMode.classify(speed: speed) }

    init(from location: CLLocation) {
        id = UUID()
        coordinate = location.coordinate
        altitude = location.altitude
        speed = max(0, location.speed)
        horizontalAccuracy = location.horizontalAccuracy
        timestamp = location.timestamp
    }
}

extension LocationPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, altitude, speed, horizontalAccuracy, timestamp
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        let lat = try c.decode(Double.self, forKey: .latitude)
        let lon = try c.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        altitude = try c.decode(Double.self, forKey: .altitude)
        speed = try c.decode(Double.self, forKey: .speed)
        horizontalAccuracy = try c.decode(Double.self, forKey: .horizontalAccuracy)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(coordinate.latitude, forKey: .latitude)
        try c.encode(coordinate.longitude, forKey: .longitude)
        try c.encode(altitude, forKey: .altitude)
        try c.encode(speed, forKey: .speed)
        try c.encode(horizontalAccuracy, forKey: .horizontalAccuracy)
        try c.encode(timestamp, forKey: .timestamp)
    }
}

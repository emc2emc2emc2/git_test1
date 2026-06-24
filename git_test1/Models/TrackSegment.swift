import Foundation

struct TrackSegment: Codable, Identifiable {
    let id: UUID
    var mode: MovementMode
    var points: [LocationPoint]
    var startLocationName: String?
    var endLocationName: String?

    var startTime: Date? { points.first?.timestamp }
    var endTime: Date?   { points.last?.timestamp }

    var duration: TimeInterval {
        guard let s = startTime, let e = endTime else { return 0 }
        return e.timeIntervalSince(s)
    }

    var averageSpeed: Double {
        guard !points.isEmpty else { return 0 }
        return points.map(\.speed).reduce(0, +) / Double(points.count)
    }

    init(id: UUID = UUID(), mode: MovementMode, points: [LocationPoint] = []) {
        self.id = id
        self.mode = mode
        self.points = points
    }
}

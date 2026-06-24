import Foundation

struct DayLog: Codable, Identifiable {
    let id: UUID
    let date: Date             // start of the calendar day
    var segments: [TrackSegment]

    var allPoints: [LocationPoint] { segments.flatMap(\.points) }

    init(date: Date = .now) {
        id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        segments = []
    }
}

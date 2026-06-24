import Foundation

struct TimelineEntry: Identifiable {
    let id = UUID()
    let segment: TrackSegment
    let timeRangeString: String
    let locationString: String
    let transitionText: String?
}

enum TimelineGenerator {

    // Compact single-line summary: "09:00 家 →開車→ 09:10 公司 (停留45分) →步行→ 09:55 便利商店"
    static func generateText(from dayLog: DayLog) -> String {
        let segments = dayLog.segments
        guard !segments.isEmpty else { return "今日尚無紀錄" }

        let fmt = makeFmt()
        var parts: [String] = []

        for (i, seg) in segments.enumerated() {
            guard let startTime = seg.startTime else { continue }

            if i == 0 {
                let loc = seg.startLocationName ?? "未知地點"
                parts.append("\(fmt.string(from: startTime)) \(loc)")
            }

            switch seg.mode {
            case .stationary:
                if let end = seg.endTime {
                    let mins = Int(end.timeIntervalSince(startTime) / 60)
                    if mins > 0 { parts.append("（停留\(mins)分）") }
                }
            case .walking:
                parts.append(" →步行→ ")
            case .vehicle:
                parts.append(" →開車→ ")
            }

            if let endTime = seg.endTime {
                let loc = seg.endLocationName ?? seg.startLocationName ?? "未知地點"
                parts.append("\(fmt.string(from: endTime)) \(loc)")
            }
        }

        return parts.joined()
    }

    // Structured entries for List display
    static func generateEntries(from dayLog: DayLog) -> [TimelineEntry] {
        let fmt = makeFmt()
        return dayLog.segments.map { seg in
            let startStr = seg.startTime.map { fmt.string(from: $0) } ?? "--:--"
            let endStr   = seg.endTime.map   { fmt.string(from: $0) } ?? "--:--"
            let sameTime = seg.startTime == seg.endTime
            let timeRange = sameTime ? startStr : "\(startStr) – \(endStr)"
            let location = seg.startLocationName ?? "未知地點"
            let transition: String? = seg.mode == .stationary ? nil : seg.mode.rawValue
            return TimelineEntry(
                segment: seg,
                timeRangeString: timeRange,
                locationString: location,
                transitionText: transition
            )
        }
    }

    private static func makeFmt() -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }
}

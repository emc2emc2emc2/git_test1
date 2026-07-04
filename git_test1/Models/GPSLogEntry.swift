import CoreLocation
import Foundation

struct GPSLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let coordinate: CLLocationCoordinate2D
    let speed: Double
    let accuracy: Double
    let mode: MovementMode

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: timestamp)
    }

    var coordString: String {
        String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
    }

    var speedString: String {
        String(format: "%.1f m/s", speed)
    }
}

import UIKit

enum MovementMode: String, Codable, CaseIterable {
    case stationary = "靜止"
    case walking    = "步行"
    case vehicle    = "開車"

    static func classify(speed: Double) -> MovementMode {
        switch speed {
        case ..<1.0:     return .stationary
        case 1.0..<3.0:  return .walking
        default:         return .vehicle
        }
    }

    var icon: String {
        switch self {
        case .stationary: return "mappin.circle.fill"
        case .walking:    return "figure.walk"
        case .vehicle:    return "car.fill"
        }
    }

    var modeArrow: String {
        switch self {
        case .stationary: return "•"
        case .walking:    return "→步行→"
        case .vehicle:    return "→開車→"
        }
    }

    var uiColor: UIColor {
        switch self {
        case .stationary: return .systemOrange
        case .walking:    return .systemGreen
        case .vehicle:    return .systemBlue
        }
    }
}

import CoreLocation
import Combine
import Foundation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?
    @Published var isTracking: Bool = false

    // Downstream consumers (TrackAnalyzer) subscribe here
    let locationPublisher = PassthroughSubject<CLLocation, Never>()

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true
        authorizationStatus = manager.authorizationStatus
        applyProfile(for: .stationary)
    }

    func requestAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func startTracking() {
        if authorizationStatus == .notDetermined {
            requestAuthorization()
            return
        }
        manager.startUpdatingLocation()
        // Fallback: if iOS kills the app, significant-change monitoring can relaunch it
        manager.startMonitoringSignificantLocationChanges()
        isTracking = true
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
        isTracking = false
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        // Discard readings with excessive horizontal error
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy < 100 else { return }

        lastLocation = location
        let mode = MovementMode.classify(speed: max(0, location.speed))
        applyProfile(for: mode)
        locationPublisher.send(location)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if (authorizationStatus == .authorizedAlways ||
            authorizationStatus == .authorizedWhenInUse) && !isTracking {
            startTracking()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] \(error.localizedDescription)")
    }

    // MARK: - Adaptive accuracy profile

    private func applyProfile(for mode: MovementMode) {
        switch mode {
        case .stationary:
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            manager.distanceFilter  = 50
        case .walking:
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.distanceFilter  = 10
        case .vehicle:
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            manager.distanceFilter  = 5
        }
    }
}

import CoreLocation
import Combine
import Foundation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?
    @Published var isTracking: Bool = false
    @Published var currentMode: MovementMode = .stationary
    @Published var logEntries: [GPSLogEntry] = []
    @Published var recordIntervalSeconds: Int = 5

    let locationPublisher = PassthroughSubject<CLLocation, Never>()

    private let manager = CLLocationManager()
    private var latestLocation: CLLocation?
    private var recordTimer: Timer?

    override init() {
        super.init()
        manager.delegate = self
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true
        authorizationStatus = manager.authorizationStatus
        applyProfile(for: .stationary)
    }

    // MARK: - Public API

    func requestAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func startTracking() {
        if authorizationStatus == .notDetermined {
            requestAuthorization()
            return
        }
        manager.startUpdatingLocation()
        manager.startMonitoringSignificantLocationChanges()
        startTimer()
        isTracking = true
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
        stopTimer()
        isTracking = false
    }

    func setRecordInterval(_ seconds: Int) {
        recordIntervalSeconds = seconds
        if isTracking {
            stopTimer()
            startTimer()
        }
    }

    func clearLog() {
        logEntries.removeAll()
    }

    // MARK: - Timer

    private func startTimer() {
        recordTimer?.invalidate()
        recordTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(recordIntervalSeconds),
            repeats: true
        ) { [weak self] _ in
            self?.saveCurrentLocation()
        }
    }

    private func stopTimer() {
        recordTimer?.invalidate()
        recordTimer = nil
    }

    private func saveCurrentLocation() {
        guard let location = latestLocation else { return }
        let entry = GPSLogEntry(
            timestamp: location.timestamp,
            coordinate: location.coordinate,
            speed: max(0, location.speed),
            accuracy: location.horizontalAccuracy,
            mode: MovementMode.classify(speed: max(0, location.speed))
        )
        logEntries.insert(entry, at: 0)

        // Publish to TrackAnalyzer pipeline
        locationPublisher.send(location)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy < 100 else { return }

        latestLocation = location
        lastLocation = location
        currentMode = MovementMode.classify(speed: max(0, location.speed))
        applyProfile(for: currentMode)
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

    // MARK: - Adaptive accuracy

    private func applyProfile(for mode: MovementMode) {
        switch mode {
        case .stationary:
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.distanceFilter  = kCLDistanceFilterNone
        case .walking:
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.distanceFilter  = kCLDistanceFilterNone
        case .vehicle:
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            manager.distanceFilter  = kCLDistanceFilterNone
        }
    }
}

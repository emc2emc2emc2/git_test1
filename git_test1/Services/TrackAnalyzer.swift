import CoreLocation
import Combine
import Foundation

final class TrackAnalyzer: ObservableObject {

    @Published var currentSegments: [TrackSegment] = []
    @Published var currentDayLog: DayLog = DayLog()

    var allCoordinates: [CLLocationCoordinate2D] {
        currentSegments.flatMap { $0.points.map(\.coordinate) }
    }

    private var cancellables = Set<AnyCancellable>()
    private var activeSegment: TrackSegment?

    // Hysteresis: require N consecutive same-mode readings before switching segments
    private var modeBuffer: [MovementMode] = []
    private let hysteresisCount = 3

    // Geocoding queue to respect Apple's ~1 req/sec rate limit
    private let geocoder = CLGeocoder()
    private var geocodeQueue: [(CLLocationCoordinate2D, (String?) -> Void)] = []
    private var geocodingInFlight = false

    init(locationManager: LocationManager) {
        locationManager.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.process($0) }
            .store(in: &cancellables)
    }

    // MARK: - Location processing

    private func process(_ location: CLLocation) {
        let point = LocationPoint(from: location)
        let rawMode = MovementMode.classify(speed: point.speed)

        // Buffer to prevent rapid oscillation between modes
        modeBuffer.append(rawMode)
        if modeBuffer.count > hysteresisCount { modeBuffer.removeFirst() }

        let resolvedMode: MovementMode
        if modeBuffer.count == hysteresisCount,
           let last = modeBuffer.last,
           modeBuffer.allSatisfy({ $0 == last }) {
            resolvedMode = last
        } else {
            resolvedMode = activeSegment?.mode ?? rawMode
        }

        if activeSegment == nil {
            activeSegment = TrackSegment(mode: resolvedMode, points: [point])
        } else if activeSegment!.mode != resolvedMode {
            finalizeCurrentSegment()
            activeSegment = TrackSegment(mode: resolvedMode, points: [point])
        } else {
            activeSegment!.points.append(point)
            // Cap memory at 10,000 points per active segment
            if activeSegment!.points.count > 10_000 {
                activeSegment!.points.removeFirst()
            }
        }

        rebuildPublished()
    }

    private func finalizeCurrentSegment() {
        guard let seg = activeSegment, !seg.points.isEmpty else { return }
        activeSegment = nil

        // Absorb short stationary blips into the preceding segment
        if seg.mode == .stationary && seg.duration < 60,
           !currentDayLog.segments.isEmpty {
            currentDayLog.segments[currentDayLog.segments.count - 1].points += seg.points
            rebuildPublished()
            return
        }

        currentDayLog.segments.append(seg)
        rebuildPublished()

        // Reverse-geocode start and end points asynchronously
        let segId = seg.id
        if let first = seg.points.first {
            enqueueGeocode(first.coordinate) { [weak self] name in
                guard let self else { return }
                if let idx = self.currentDayLog.segments.firstIndex(where: { $0.id == segId }) {
                    self.currentDayLog.segments[idx].startLocationName = name
                    self.rebuildPublished()
                }
            }
        }
        if let last = seg.points.last, seg.points.count > 1 {
            enqueueGeocode(last.coordinate) { [weak self] name in
                guard let self else { return }
                if let idx = self.currentDayLog.segments.firstIndex(where: { $0.id == segId }) {
                    self.currentDayLog.segments[idx].endLocationName = name
                    self.rebuildPublished()
                }
            }
        }
    }

    private func rebuildPublished() {
        var all = currentDayLog.segments
        if let active = activeSegment { all.append(active) }
        currentSegments = all
    }

    func rolloverDay() {
        finalizeCurrentSegment()
        PersistenceManager.shared.save(dayLog: currentDayLog)
        currentDayLog = DayLog()
        currentSegments = []
        modeBuffer = []
    }

    // MARK: - Geocoding (serialised queue, ~1 request per second)

    private func enqueueGeocode(_ coordinate: CLLocationCoordinate2D,
                                 completion: @escaping (String?) -> Void) {
        geocodeQueue.append((coordinate, completion))
        drainGeocodeQueue()
    }

    private func drainGeocodeQueue() {
        guard !geocodingInFlight, !geocodeQueue.isEmpty else { return }
        let (coord, completion) = geocodeQueue.removeFirst()
        geocodingInFlight = true

        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            let name = placemarks?.first.flatMap { p in
                [p.name, p.thoroughfare, p.locality].compactMap { $0 }.first
            }
            DispatchQueue.main.async {
                completion(name)
                self?.geocodingInFlight = false
                self?.drainGeocodeQueue()
            }
        }
    }
}

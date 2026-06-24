import MapKit
import Combine
import Foundation

@MainActor
final class MapViewModel: ObservableObject {

    @Published var segmentedPolylines: [(polyline: MKPolyline, mode: MovementMode)] = []
    @Published var followsUser: Bool = true

    // Fired when the user taps the re-center button
    let recenterTrigger = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()

    func bind(to analyzer: TrackAnalyzer, locationManager: LocationManager) {
        // Rebuild polylines whenever segments update
        analyzer.$currentSegments
            .receive(on: RunLoop.main)
            .sink { [weak self] segments in
                self?.rebuildPolylines(from: segments)
            }
            .store(in: &cancellables)

        // Initial state
        rebuildPolylines(from: analyzer.currentSegments)
    }

    private func rebuildPolylines(from segments: [TrackSegment]) {
        segmentedPolylines = segments.compactMap { seg in
            guard seg.points.count >= 2 else { return nil }
            let coords = seg.points.map(\.coordinate)
            return (MKPolyline(coordinates: coords, count: coords.count), seg.mode)
        }
    }
}

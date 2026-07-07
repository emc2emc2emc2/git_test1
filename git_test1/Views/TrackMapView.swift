import SwiftUI
import MapKit
import Combine

struct TrackMapView: UIViewRepresentable {
    var segmentedPolylines: [(polyline: MKPolyline, mode: MovementMode)]
    var recenterTrigger: PassthroughSubject<Void, Never>

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let mv = MKMapView()
        mv.delegate = context.coordinator
        mv.showsUserLocation = true
        mv.userTrackingMode = .follow
        context.coordinator.subscribe(to: recenterTrigger, mapView: mv)
        return mv
    }

    func updateUIView(_ mv: MKMapView, context: Context) {
        mv.removeOverlays(mv.overlays)
        context.coordinator.modeMap.removeAll()

        for (polyline, mode) in segmentedPolylines {
            context.coordinator.modeMap[polyline] = mode
            mv.addOverlay(polyline)
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        var modeMap: [MKPolyline: MovementMode] = [:]
        private var cancellable: AnyCancellable?

        func subscribe(to trigger: PassthroughSubject<Void, Never>, mapView: MKMapView) {
            cancellable = trigger.sink { [weak mapView] in
                mapView?.setUserTrackingMode(.follow, animated: true)
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let poly = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: poly)
            let mode = modeMap[poly] ?? .walking
            renderer.strokeColor = mode.uiColor
            renderer.lineWidth = 4
            renderer.alpha = 0.85
            return renderer
        }
    }
}

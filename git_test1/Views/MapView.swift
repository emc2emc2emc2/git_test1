import SwiftUI
import CoreLocation

struct MapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var mapVM: MapViewModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            TrackMapView(
                segmentedPolylines: mapVM.segmentedPolylines,
                recenterTrigger: mapVM.recenterTrigger
            )
            .ignoresSafeArea()

            // Current movement mode badge
            VStack(alignment: .leading, spacing: 8) {
                if let loc = locationManager.lastLocation {
                    let mode = MovementMode.classify(speed: max(0, loc.speed))
                    Label(mode.rawValue, systemImage: mode.icon)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(mode.uiColor), in: Capsule())
                }

                if !mapVM.segmentedPolylines.isEmpty {
                    Text("\(mapVM.segmentedPolylines.count) 段軌跡")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .padding(.top, 8)
            .padding(.leading, 12)

            // Re-centre button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        mapVM.recenterTrigger.send()
                    } label: {
                        Image(systemName: "location.fill")
                            .padding(14)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding()
                }
            }
        }
    }
}

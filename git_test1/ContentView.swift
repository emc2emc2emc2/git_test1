import SwiftUI
import MapKit

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var analyzer: TrackAnalyzer

    // Start with Taiwan as default; updates to real location when available
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    ))
    @State private var followsUser = true

    private let intervalOptions = [1, 3, 5, 10, 30, 60]

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {

                // ── MAP ──────────────────────────────────────────
                Map(position: $cameraPosition) {
                    UserAnnotation()
                    ForEach(analyzer.currentSegments) { seg in
                        if seg.points.count >= 2 {
                            MapPolyline(coordinates: seg.points.map(\.coordinate))
                                .stroke(Color(seg.mode.uiColor), lineWidth: 4)
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .frame(height: geo.size.height * 0.48)
                // Move camera when a new location arrives
                .onChange(of: locationManager.lastLocation) { _, loc in
                    guard let loc, followsUser else { return }
                    withAnimation(.easeInOut(duration: 0.5)) {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: loc.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                        ))
                    }
                }
                // Stop auto-follow when user drags the map
                .onMapCameraChange { _ in
                    followsUser = false
                }

                // ── CONTROLS ─────────────────────────────────────
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        // Mode badge
                        Label(locationManager.currentMode.rawValue,
                              systemImage: locationManager.currentMode.icon)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color(locationManager.currentMode.uiColor))

                        Spacer()

                        // Re-center button
                        Button {
                            followsUser = true
                            if let loc = locationManager.lastLocation {
                                withAnimation {
                                    cameraPosition = .region(MKCoordinateRegion(
                                        center: loc.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                    ))
                                }
                            }
                        } label: {
                            Image(systemName: followsUser ? "location.fill" : "location")
                                .foregroundStyle(followsUser ? .blue : .secondary)
                        }

                        // Interval picker
                        Text("每")
                            .font(.subheadline)
                        Picker("", selection: $locationManager.recordIntervalSeconds) {
                            ForEach(intervalOptions, id: \.self) { s in
                                Text("\(s) 秒").tag(s)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: locationManager.recordIntervalSeconds) { _, val in
                            locationManager.setRecordInterval(val)
                        }
                        Text("記錄")
                            .font(.subheadline)
                    }

                    HStack(spacing: 12) {
                        // Coordinates
                        if let loc = locationManager.lastLocation {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(format: "%.5f, %.5f",
                                            loc.coordinate.latitude,
                                            loc.coordinate.longitude))
                                    .font(.system(.caption, design: .monospaced))
                                Text(String(format: "精度 ±%.0fm　速度 %.1f m/s",
                                            loc.horizontalAccuracy,
                                            max(0, loc.speed)))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text(locationManager.authorizationStatus == .denied
                                 ? "請在設定中開啟定位權限"
                                 : "等待 GPS 訊號…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Start / Stop
                        Button {
                            if locationManager.isTracking {
                                locationManager.stopTracking()
                            } else {
                                followsUser = true
                                locationManager.startTracking()
                            }
                        } label: {
                            Text(locationManager.isTracking ? "停止" : "開始追蹤")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    locationManager.isTracking ? Color.red : Color.blue,
                                    in: Capsule()
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))

                Divider()

                // ── GPS LOG ──────────────────────────────────────
                HStack {
                    Text("GPS 記錄")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text("（\(locationManager.logEntries.count) 筆）")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("清除") { locationManager.clearLog() }
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color(.systemGroupedBackground))

                if locationManager.logEntries.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "location.slash")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 8)
                        Text("按「開始追蹤」後\n每隔設定秒數自動記錄一筆")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                } else {
                    List(locationManager.logEntries) { entry in
                        LogEntryRow(entry: entry)
                    }
                    .listStyle(.plain)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            locationManager.startTracking()
        }
    }
}

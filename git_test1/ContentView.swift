import SwiftUI
import MapKit

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var analyzer: TrackAnalyzer

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    private let intervalOptions = [1, 3, 5, 10, 30, 60]

    var body: some View {
        VStack(spacing: 0) {

            // ── MAP ──────────────────────────────────────────
            Map(position: $cameraPosition) {
                UserAnnotation()

                // Draw track coloured by movement mode
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
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.height * 0.48)

            // ── CONTROLS ─────────────────────────────────────
            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    // Current mode badge
                    Label(locationManager.currentMode.rawValue,
                          systemImage: locationManager.currentMode.icon)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(locationManager.currentMode.uiColor))

                    Spacer()

                    // Interval picker
                    HStack(spacing: 4) {
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
                        Text("記錄一次")
                            .font(.subheadline)
                    }
                }

                HStack(spacing: 12) {
                    // Coordinates display
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
                        Text("等待 GPS 訊號…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Start / Stop button
                    Button {
                        locationManager.isTracking
                            ? locationManager.stopTracking()
                            : locationManager.startTracking()
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
                    Text("按「開始追蹤」後每隔設定秒數自動記錄一筆")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
            } else {
                List(locationManager.logEntries) { entry in
                    LogEntryRow(entry: entry)
                }
                .listStyle(.plain)
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            locationManager.startTracking()
        }
    }
}

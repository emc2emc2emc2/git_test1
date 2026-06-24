import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        NavigationView {
            Form {
                Section("追蹤狀態") {
                    HStack {
                        Text("目前狀態")
                        Spacer()
                        Text(locationManager.isTracking ? "追蹤中" : "已停止")
                            .foregroundStyle(locationManager.isTracking ? .green : .secondary)
                    }
                    Button(locationManager.isTracking ? "停止追蹤" : "開始追蹤") {
                        locationManager.isTracking
                            ? locationManager.stopTracking()
                            : locationManager.startTracking()
                    }
                }

                Section("定位授權") {
                    HStack {
                        Text("授權狀態")
                        Spacer()
                        Text(authStatusText)
                            .foregroundStyle(authStatusColor)
                    }
                    if locationManager.authorizationStatus != .authorizedAlways {
                        Button("前往設定開啟「永遠允許」") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }

                Section("速度模式說明") {
                    Label("< 1 m/s：靜止（50m 更新，省電）",
                          systemImage: MovementMode.stationary.icon)
                        .foregroundStyle(Color(MovementMode.stationary.uiColor))
                    Label("1–3 m/s：步行（10m 精度）",
                          systemImage: MovementMode.walking.icon)
                        .foregroundStyle(Color(MovementMode.walking.uiColor))
                    Label("> 3 m/s：開車（最佳導航精度）",
                          systemImage: MovementMode.vehicle.icon)
                        .foregroundStyle(Color(MovementMode.vehicle.uiColor))
                }
            }
            .navigationTitle("設定")
        }
    }

    private var authStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:       return "尚未決定"
        case .restricted:          return "受限制"
        case .denied:              return "已拒絕"
        case .authorizedWhenInUse: return "使用時允許"
        case .authorizedAlways:    return "永遠允許"
        @unknown default:          return "未知"
        }
    }

    private var authStatusColor: Color {
        locationManager.authorizationStatus == .authorizedAlways ? .green : .orange
    }
}

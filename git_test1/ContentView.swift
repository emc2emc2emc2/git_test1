//
//  ContentView.swift
//  git_test1
//
//  Created by emc2 on 2025/6/8.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var analyzer: TrackAnalyzer
    @StateObject private var mapVM = MapViewModel()
    @StateObject private var timelineVM = TimelineViewModel()

    var body: some View {
        TabView {
            MapView()
                .environmentObject(mapVM)
                .tabItem { Label("地圖", systemImage: "map.fill") }

            TimelineView()
                .environmentObject(timelineVM)
                .tabItem { Label("時間軸", systemImage: "clock.fill") }

            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
        }
        .onAppear {
            mapVM.bind(to: analyzer, locationManager: locationManager)
            timelineVM.bind(to: analyzer)
        }
    }
}

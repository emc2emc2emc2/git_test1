//
//  git_test1App.swift
//  git_test1
//
//  Created by emc2 on 2025/6/8.
//

import SwiftUI

@main
struct git_test1App: App {
    @StateObject private var locationManager: LocationManager
    @StateObject private var analyzer: TrackAnalyzer

    init() {
        let lm = LocationManager()
        _locationManager = StateObject(wrappedValue: lm)
        _analyzer = StateObject(wrappedValue: TrackAnalyzer(locationManager: lm))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(analyzer)
                .onReceive(NotificationCenter.default.publisher(
                    for: UIApplication.significantTimeChangeNotification)) { _ in
                    analyzer.rolloverDay()
                }
        }
    }
}

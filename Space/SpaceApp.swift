//
//  SpaceApp.swift
//  Space
//
//  Created by Ismail Mohammed on 2025-12-30.
//

import SwiftUI
import SwiftData

@main
struct SpaceApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TabView {
                    DailyPage()
                        .tabItem { Label("Daily", systemImage: "calendar") }

                    ISSMapView()
                        .tabItem { Label("ISS", systemImage: "sparkles") }
                }
            }
        }
    }
}


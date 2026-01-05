//
//  PlanetDetailSheet.swift
//  Space
//
//  Created by Ismail Mohammed on 2026-01-05.
//

import SwiftUI

struct PlanetDetailSheet: View {
    let planet: VisibleBody
    let location: LocationManager

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Point towards object") {
                    CompassView(
                        heading: location.headingDegrees,
                        targetAzimuth: planet.azimuth
                    )
                    .frame(height: 280)

                    if let h = location.headingDegrees {
                        Text("You: \(Int(h.rounded()))° • Planet: \(Int(planet.azimuth.rounded()))°")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Waiting for compass…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    HStack {
                        Text("Constellation")
                        Spacer()
                        Text(planet.constellation ?? "—").foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Magnitude")
                        Spacer()
                        if let mag = planet.magnitude {
                            Text(String(format: "%.1f", mag)).foregroundStyle(.secondary)
                        } else {
                            Text("—").foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Position") {
                    HStack {
                        Text("Altitude")
                        Spacer()
                        Text("\(Int(planet.altitude.rounded()))°").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Azimuth")
                        Spacer()
                        Text("\(Int(planet.azimuth.rounded()))°").foregroundStyle(.secondary)
                    }
                }

                if let phase = planet.phase {
                    Section("Moon") {
                        HStack {
                            Text("Phase")
                            Spacer()
                            Text("\(String(format: "%.0f", phase))%").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(planet.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear { location.startHeading() }
        .onDisappear { location.stopHeading() }
    }
}

//
//  PlanetsView.swift
//  Space
//
//  Created by Ismail Mohammed on 2026-01-03.
//


import SwiftUI
import CoreLocation

struct PlanetsView: View {
    @State private var vm = PlanetsViewModel()
    @State private var location = LocationManager()

    var body: some View {
        List {
            Section("Din plats") {
                if let c = location.coordinate {
                    Text("Lat: \(String(format: "%.4f", c.latitude)), Long: \(String(format: "%.4f", c.longitude))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Hämtar position…")
                }

                if let err = location.errorMessage {
                    Text(err)
                        .foregroundStyle(.red)
                }
            }

            Section("Synliga objekt") {
                if vm.isLoading {
                    Text("Laddar…")
                } else if let err = vm.errorMessage {
                    Text(err).foregroundStyle(.red)
                } else if vm.bodies.isEmpty {
                    Text("Inga objekt att visa just nu.")
                } else {
                    ForEach(vm.bodies) { b in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(b.name)
                                    .font(.headline)

                                Spacer()

                                // Naked eye indicator
                                if let naked = b.nakedEyeObject {
                                    Text(naked ? "Naked eye" : "Teleskop")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(naked ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }

                            // Alt/Az + magnitud + constellation
                            Text(detailLine(for: b))
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            // Moon phase %
                            if let phase = b.phase {
                                Text("Fas: \(String(format: "%.0f", phase))%")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Sky")
        .toolbar {
            Button("Refresh") {
                Task { await refresh() }
            }
        }
        .overlay {
            if vm.isLoading { ProgressView() }
        }
        .task {
            location.requestPermissionAndStart()
            await refresh()
        }
        .onChange(of: location.coordinate?.latitude) { _, _ in
            Task { await refresh() }
        }
    }

    private func refresh() async {
        guard let c = location.coordinate else { return }
        await vm.load(latitude: c.latitude, longitude: c.longitude)
    }

    private func detailLine(for b: VisibleBody) -> String {
        var parts: [String] = []
        parts.append("Alt: \(Int(b.altitude.rounded()))°")
        parts.append("Az: \(Int(b.azimuth.rounded()))°")

        if let mag = b.magnitude {
            parts.append(String(format: "Mag: %.1f", mag))
        }
        if let con = b.constellation {
            parts.append(con)
        }
        return parts.joined(separator: " • ")
    }
}

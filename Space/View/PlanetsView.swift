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
    @State private var selectedBody: VisibleBody?

    var body: some View {
        List {
            Section("Visible Objects") {
                if vm.isLoading {
                    Text("Loading…")
                } else if let err = vm.errorMessage {
                    Text(err).foregroundStyle(.red)
                } else if vm.bodies.isEmpty {
                    Text("No objects to show right now.")
                } else {
                    ForEach(vm.bodies) { b in
                        Button {
                            selectedBody = b
                        } label: {
                            row(for: b)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)) 
                    }

                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(SpaceBackground())
        .navigationTitle("Sky")
        .overlay {
            if vm.isLoading { ProgressView() }
        }
        .refreshable {
            await refresh() }
        .task {
            location.requestPermissionAndStart()
            await refresh()
        }
        .onChange(of: location.coordinate?.latitude) { _, _ in
            Task { await refresh() }
        }
        .sheet(item: $selectedBody) { planet in
            PlanetDetailSheet(planet: planet, location: location)
        }
    }

    private func row(for b: VisibleBody) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(b.name)
                    .font(.headline)

                Spacer()

                if let naked = b.nakedEyeObject {
                    Text(naked ? "Naked eye" : "Telescope")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(naked ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            Text(detailLine(for: b))
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let phase = b.phase {
                Text("Phase: \(String(format: "%.0f", phase))%")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func refresh() async {
        guard let c = location.coordinate else { return }
        await vm.load(latitude: c.latitude, longitude: c.longitude)
    }

    private func detailLine(for b: VisibleBody) -> String {
        let azDir = compassDirection(fromAzimuth: b.azimuth)

        var parts: [String] = []
        parts.append("Alt: \(Int(b.altitude.rounded()))°")
        parts.append("Az: \(Int(b.azimuth.rounded()))° (\(azDir))")

        if let mag = b.magnitude {
            parts.append(String(format: "Mag: %.1f", mag))
        }
        if let con = b.constellation {
            parts.append(con)
        }
        return parts.joined(separator: " • ")
    }

    private func compassDirection(fromAzimuth degrees: Double) -> String {
        let dirs = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"]
        let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let index = Int((normalized / 22.5).rounded()) % 16
        return dirs[index]
    }
}

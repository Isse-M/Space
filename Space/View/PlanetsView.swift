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
                        Button {
                            selectedBody = b
                        } label: {
                            row(for: b)
                        }
                        .buttonStyle(.plain)
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
                    Text(naked ? "Naked eye" : "Teleskop")
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
                Text("Fas: \(String(format: "%.0f", phase))%")
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

private struct PlanetDetailSheet: View {
    let planet: VisibleBody
    let location: LocationManager

    @Environment(\.dismiss) private var dismiss

    private var pointerRotation: Double {
        let heading = location.headingDegrees ?? 0
        return planet.azimuth - heading
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Rikta mot objektet") {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(.secondary.opacity(0.25), lineWidth: 2)
                                .frame(width: 160, height: 160)

                            Text("Here")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .offset(y: -86)

                            Image(systemName: "location.north.fill")
                                .font(.system(size: 46, weight: .semibold))
                                .rotationEffect(.degrees(pointerRotation))
                                .animation(.easeOut(duration: 0.12), value: location.headingDegrees)
                        }

                        if let h = location.headingDegrees {
                            Text("Du pekar: \(Int(h.rounded()))° • Mål: \(Int(planet.azimuth.rounded()))°")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Väntar på kompass…")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                }

                Section {
                    HStack {
                        Text("Konstellation")
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
                    Section("Månen") {
                        HStack {
                            Text("Fas")
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
        .onAppear {
            location.startHeading()
        }
        .onDisappear {
            location.stopHeading()
        }
    }
}

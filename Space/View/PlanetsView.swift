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

private struct PlanetDetailSheet: View {
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

struct CompassView: View {
    let heading: Double?
    let targetAzimuth: Double

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                ZStack {
                    CompassRose()
                        .aspectRatio(1, contentMode: .fit)
                        .rotationEffect(.degrees(-(heading ?? 0)))

                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(.red)
                        .scaleEffect(x: 0.5, y: 4)
                        .rotationEffect(.degrees(targetAzimuth - (heading ?? 0)))
                }
            }
            .padding(12)

            HStack(spacing: 16) {
                legendItem(color: .red, title: "Planet")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private var rotationDegrees: Double {
        let h = heading ?? 0
        return h - targetAzimuth
    }

    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(title)
        }
    }
}

private struct CompassRose: View {
    var body: some View {
        Canvas { context, size in
            let geom = Geometry(size: size)

            context.stroke(
                Path(ellipseIn: geom.circleRect),
                with: .color(.secondary.opacity(0.35)),
                lineWidth: 3
            )

            for deg in geom.degrees {
                let style = TickStyle(deg: deg)
                let line = geom.tickLine(for: deg, length: style.length)
                context.stroke(line, with: .color(.secondary.opacity(0.6)), lineWidth: style.width)

                if style.shouldLabel, let label = labelFor(deg) {
                    context.draw(
                        Text(label).font(.caption).foregroundStyle(.secondary),
                        at: geom.labelPoint(for: deg),
                        anchor: .center
                    )
                }
            }
        }
    }

    private func labelFor(_ deg: Int) -> String? {
        switch deg {
        case 0: return "N"
        case 45: return "NE"
        case 90: return "E"
        case 135: return "SE"
        case 180: return "S"
        case 225: return "SW"
        case 270: return "W"
        case 315: return "NW"
        default: return nil
        }
    }

    private struct TickStyle {
        let length: CGFloat
        let width: CGFloat
        let shouldLabel: Bool

        init(deg: Int) {
            let isCardinal = deg % 90 == 0
            let isIntercardinal = deg % 45 == 0

            self.length = isCardinal ? 16 : (isIntercardinal ? 11 : 6)
            self.width = isCardinal ? 3 : 1
            self.shouldLabel = isIntercardinal
        }
    }

    private struct Geometry {
        let size: CGSize
        let r: CGFloat
        let center: CGPoint
        let degrees: [Int]

        init(size: CGSize) {
            self.size = size
            self.r = min(size.width, size.height) / 2
            self.center = CGPoint(x: size.width / 2, y: size.height / 2)
            self.degrees = Array(stride(from: 0, to: 360, by: 15))
        }

        var circleRect: CGRect {
            CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)
        }

        func labelPoint(for deg: Int) -> CGPoint {
            let a = angleRadians(for: deg)
            let ca = CGFloat(cos(a))
            let sa = CGFloat(sin(a))

            return CGPoint(
                x: center.x + (r - 34) * ca,
                y: center.y + (r - 34) * sa
            )
        }

        func tickLine(for deg: Int, length: CGFloat) -> Path {
            let a = angleRadians(for: deg)
            let ca = CGFloat(cos(a))
            let sa = CGFloat(sin(a))

            let p1 = CGPoint(
                x: center.x + (r - 10) * ca,
                y: center.y + (r - 10) * sa
            )
            let p2 = CGPoint(
                x: center.x + (r - 10 - length) * ca,
                y: center.y + (r - 10 - length) * sa
            )

            var path = Path()
            path.move(to: p1)
            path.addLine(to: p2)
            return path
        }

        func angleRadians(for deg: Int) -> Double {
            (Double(deg) * .pi / 180) - (.pi / 2)
        }
    }
}

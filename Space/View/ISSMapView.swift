//
//  ISSMapView.swift
//  Space
//
//  Created by Ismail Mohammed on 2026-01-01.
//


import SwiftUI
import MapKit
import CoreLocation

private struct LatLon: Equatable {
    let lat: Double?
    let lon: Double?
}

struct ISSMapView: View {
    @State private var vm = ISSMapViewModel()

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
        )
    )

    @State private var hasCenteredInitially = false

    var body: some View {
        ZStack(alignment: .bottom) {

            Map(position: $cameraPosition, interactionModes: .all) {
                if let coord = vm.coordinate {
                    Annotation("ISS", coordinate: coord) {
                        Image(systemName: "sparkles")
                            .font(.title)
                            .padding(8)
                            .background(.thinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .onAppear { vm.start() }
            .onDisappear { vm.stop() }

            
            .onChange(of: LatLon(lat: vm.iss?.latitude, lon: vm.iss?.longitude)) { _, newValue in
                guard !hasCenteredInitially,
                      let lat = newValue.lat,
                      let lon = newValue.lon
                else { return }

                hasCenteredInitially = true
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                recenter(on: coord, span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60))
            }

            infoPanel
        }
    }

    private var infoPanel: some View {
        VStack(spacing: 10) {

            HStack {
                Spacer()
                Button("Recenter") {
                    guard let coord = vm.coordinate else { return }
                    recenter(on: coord, span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15))
                }
            }

            HStack {
                stat("Höjd", vm.altitudeText)
                stat("Hastighet", vm.velocityText)
            }

            HStack {
                Text("Senast: \(vm.timestampText)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()

                if let err = vm.errorMessage {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding()
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func recenter(on coord: CLLocationCoordinate2D, span: MKCoordinateSpan) {
        withAnimation(.easeInOut(duration: 0.9)) {
            cameraPosition = .region(
                MKCoordinateRegion(center: coord, span: span)
            )
        }
    }
}

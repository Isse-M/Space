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
    @State private var cameraPosition: MapCameraPosition = .automatic

    @State private var ignoreUserCameraChanges = false

    var body: some View {
        ZStack(alignment: .bottom) {

            Map(position: $cameraPosition, interactionModes: .all) {
                if let coord = vm.coordinate {
                    Annotation("ISS", coordinate: coord) {
                        Image(systemName: "sparkles") // byt till egen ISS-ikon om du vill
                            .font(.title)
                            .padding(8)
                            .background(.thinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .onAppear {
                vm.start()
            }
            .onDisappear { vm.stop() }

            .onMapCameraChange(frequency: .continuous) { _ in
                guard !ignoreUserCameraChanges else { return }
                if vm.isFollowingISS {
                    vm.isFollowingISS = false
                }
            }

            // Följ ISS: när lat/lon uppdateras, flytta kameran (men bara om follow är på).
            .onChange(of: LatLon(lat: vm.iss?.latitude, lon: vm.iss?.longitude)) { _, newValue in
                guard vm.isFollowingISS,
                      let lat = newValue.lat,
                      let lon = newValue.lon
                else { return }

                let newCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)

                ignoreUserCameraChanges = true
                withAnimation(.easeInOut(duration: 0.8)) {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: newCoord,
                            span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
                        )
                    )
                }

                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 900_000_000)
                    ignoreUserCameraChanges = false
                }
            }

            infoPanel
        }
    }

    private var infoPanel: some View {
        VStack(spacing: 10) {

            HStack {
                Toggle("Följ ISS", isOn: $vm.isFollowingISS)
                    .toggleStyle(.switch)

                Spacer()

                Button("Recenter") {
                    vm.isFollowingISS = true

                    guard let coord = vm.coordinate else { return }

                    ignoreUserCameraChanges = true
                    withAnimation(.easeInOut(duration: 0.8)) {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: coord,
                                span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
                            )
                        )
                    }
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 900_000_000)
                        ignoreUserCameraChanges = false
                    }
                }
            }

            HStack {
                stat("Höjd", vm.altitudeText)     // bör visa “km” i din VM-formattering
                stat("Hastighet", vm.velocityText) // bör visa “km/h”
                stat("Sikt", vm.visibilityText)
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
}

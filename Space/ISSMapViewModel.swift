//
//  ISSMapViewModel.swift
//  Space
//
//  Created by Ismail Mohammed on 2026-01-01.
//


import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class ISSMapViewModel {
    private let service: ISSServicing
    private var pollingTask: Task<Void, Never>?

    var iss: ISSState?
    var errorMessage: String?

    var isFollowingISS: Bool = true

    init(service: ISSServicing = ISSService()) {
        self.service = service
    }

    func start() {
        guard pollingTask == nil else { return }

        pollingTask = Task {
            while !Task.isCancelled {
                do {
                    let state = try await service.fetchISS()

                    iss = state
                    errorMessage = nil
                } catch {
                    errorMessage = error.localizedDescription
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let iss else { return nil }
        return CLLocationCoordinate2D(latitude: iss.latitude, longitude: iss.longitude)
    }

    var altitudeText: String {
        guard let iss else { return "—" }
        return String(format: "%.0f km", iss.altitude)
    }

    var velocityText: String {
        guard let iss else { return "—" }
        return String(format: "%.0f km/h", iss.velocity)
    }

    var visibilityText: String {
        iss?.visibility ?? "—"
    }

    var timestampText: String {
        guard let iss else { return "—" }
        let date = Date(timeIntervalSince1970: iss.timestamp)
        return date.formatted(date: .abbreviated, time: .standard)
    }
}

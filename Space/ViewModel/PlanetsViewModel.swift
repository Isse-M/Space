//
//  PlanetsViewModel.swift
//  Space
//
//  Created by Ismail Mohammed on 2026-01-03.
//


import Foundation
import Observation

@MainActor
@Observable
final class PlanetsViewModel {
    private let service: VisiblePlanetsServicing = VisiblePlanetsService()

    var bodies: [VisibleBody] = []

    var isLoading = false
    var errorMessage: String?

    func load(latitude: Double, longitude: Double) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await service.fetchVisibleBodies(latitude: latitude, longitude: longitude)
            bodies = response.data.sorted { $0.altitude > $1.altitude }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

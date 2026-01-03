//
//  DailyViewModel.swift
//  Space
//
//  Created by Max Masuch on 2026-01-03.
//

import Foundation
import Observation

@MainActor
@Observable
final class DailyViewModel {
    private let service: APODServicing

    var apod: APODState?
    var isLoading = false
    var errorMessage: String?

    init(service: APODServicing = APODService()) {
        self.service = service
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            apod = try await service.fetchAPOD()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}



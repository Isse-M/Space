//
//  APODService.swift
//  Space
//
//  Created by Max Masuch on 2026-01-03.
//

import Foundation

protocol APODServicing {
    func fetchAPOD() async throws -> APODState
}

final class APODService: APODServicing {

    func fetchAPOD() async throws -> APODState {
        let url = URL(
            string: "https://api.nasa.gov/planetary/apod?api_key=FPQq48mAI3cfDWZ9T7psr1RnQwguIqXP6f35aKMi&thumbs=true"
        )!

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(APODState.self, from: data)
    }
}

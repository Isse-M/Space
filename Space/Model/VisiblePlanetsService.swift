//
//  VisiblePlanetsService.swift
//  Space
//
//  Created by Ismail Mohammed on 2026-01-03.
//

import Foundation

protocol VisiblePlanetsServicing {
    func fetchVisibleBodies(latitude: Double, longitude: Double) async throws -> VisiblePlanetsResponse
}

final class VisiblePlanetsService: VisiblePlanetsServicing {
    func fetchVisibleBodies(latitude: Double, longitude: Double) async throws -> VisiblePlanetsResponse {
        var components = URLComponents(string: "https://api.visibleplanets.dev/v3")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "showCoords", value: "true")
        ]

        let url = components.url!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(VisiblePlanetsResponse.self, from: data)
    }
}

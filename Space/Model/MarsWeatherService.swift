//
//  MarsWeatherService.swift
//  Space
//
//  Created by Max Masuch on 2026-01-03.
//

import Foundation

protocol MarsWeatherServicing {
    func fetchMarsWeather() async throws -> MarsWeatherResponse
}

final class MarsWeatherService: MarsWeatherServicing {
    private let session: URLSession
    

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchMarsWeather() async throws -> MarsWeatherResponse {
        let url = URL(string: "https://api.nasa.gov/insight_weather/?api_key=FPQq48mAI3cfDWZ9T7psr1RnQwguIqXP6f35aKMi&feedtype=json&ver=1.0")!

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "non-utf8"
            throw NSError(
                domain: "HTTP",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(body)"]
            )
        }

        return try JSONDecoder().decode(MarsWeatherResponse.self, from: data)
    }
}

//
//  VisiblePlanetsResponse.swift
//  Space
//
//  Created by Ismail Mohammed on 2026-01-03.
//


import Foundation

struct VisiblePlanetsResponse: Decodable {
    let data: [VisibleBody]
}

struct VisibleBody: Decodable, Identifiable {
    // API:t följer JSON:API och har ett id per body enligt README. [page:0]
    let id: String
    let type: String?
    let attributes: Attributes

    var name: String { attributes.name }
    var altitude: Double { attributes.altitude }
    var azimuth: Double { attributes.azimuth }
    var magnitude: Double? { attributes.magnitude }
    var constellation: String? { attributes.constellation }

    struct Attributes: Decodable {
        let name: String
        let altitude: Double
        let azimuth: Double
        let magnitude: Double?
        let constellation: String?
    }
}

protocol VisiblePlanetsServicing {
    func fetchVisibleBodies(latitude: Double, longitude: Double) async throws -> [VisibleBody]
}

final class VisiblePlanetsService: VisiblePlanetsServicing {
    func fetchVisibleBodies(latitude: Double, longitude: Double) async throws -> [VisibleBody] {
        var components = URLComponents(string: "https://api.visibleplanets.dev/v3")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude))
            // aboveHorizon default true enligt README, så vi behöver inte skicka den. [page:0]
        ]

        let url = components.url!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(VisiblePlanetsResponse.self, from: data)
        return decoded.data
    }
}
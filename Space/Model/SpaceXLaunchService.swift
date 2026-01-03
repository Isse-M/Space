//
//  SpaceXLaunchService.swift
//  Space
//
//  Created by Max Masuch on 2026-01-03.
//

import Foundation

protocol SpaceXLaunchServicing {
    func fetchUpcomingLaunches() async throws -> [SpaceXLaunch]
}

final class SpaceXLaunchService: SpaceXLaunchServicing {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchUpcomingLaunches() async throws -> [SpaceXLaunch] {
        let url = URL(string: "https://api.spacexdata.com/v4/launches/upcoming")!

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode([SpaceXLaunch].self, from: data)
    }
}

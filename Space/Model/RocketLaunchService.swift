//
//  SpaceXLaunchService.swift
//  Space
//
//  Created by Max Masuch on 2026-01-03.
//

import Foundation

protocol RocketLaunchServicing {
    func fetchNextLaunches(limit: Int) async throws -> [RocketLaunchState]
}

final class RocketLaunchService: RocketLaunchServicing {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchNextLaunches(limit: Int = 5) async throws -> [RocketLaunchState] {
        let url = URL(string: "https://fdo.rocketlaunch.live/json/launches/next/\(limit)")!

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(RocketLaunchResponse.self, from: data)
        return decoded.result
    }
}


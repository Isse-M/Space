//
//  ISSService.swift
//  Space
//
//  Created by Ismail Mohammed on 2026-01-01.
//


import Foundation

protocol ISSServicing {
    func fetchISS() async throws -> ISSState
}

final class ISSService: ISSServicing {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchISS() async throws -> ISSState {
        let url = URL(string: "https://api.wheretheiss.at/v1/satellites/25544")!

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(ISSState.self, from: data)
    }
}

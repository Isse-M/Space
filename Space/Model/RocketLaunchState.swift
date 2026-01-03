//
//  SpaceXLaunch.swift
//  Space
//
//  Created by Max Masuch on 2026-01-03.
//

import Foundation

struct RocketLaunchResponse: Decodable {
    let result: [RocketLaunchState]
}

struct RocketLaunchState: Decodable, Identifiable, Equatable {
    let id: Int
    let name: String
    let provider: Provider
    let vehicle: Vehicle

    let winOpen: String?
    let t0: String?
    let dateStr: String

    enum CodingKeys: String, CodingKey {
        case id, name, provider, vehicle
        case winOpen = "win_open"
        case t0
        case dateStr = "date_str"
    }

    struct Provider: Decodable, Equatable {
        let name: String
    }

    struct Vehicle: Decodable, Equatable {
        let name: String
    }
}

//
//  SpaceXLaunch.swift
//  Space
//
//  Created by Max Masuch on 2026-01-03.
//

import Foundation

struct SpaceXLaunch: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let dateUTC: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case dateUTC = "date_utc"
    }
}

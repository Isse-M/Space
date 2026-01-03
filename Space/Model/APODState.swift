//
//  APODState.swift
//  Space
//
//  Created by Max Masuch on 2026-01-03.
//

import Foundation

struct APODState: Decodable, Equatable, Identifiable {
    var id: String { date }

    let date: String
    let title: String
    let explanation: String
    let url: URL
    let hdurl: URL?
    let mediaType: String

    enum CodingKeys: String, CodingKey {
        case date, title, explanation, url, hdurl
        case mediaType = "media_type"
    }

    var isImage: Bool { mediaType == "image" }
}

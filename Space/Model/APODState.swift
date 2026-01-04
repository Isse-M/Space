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

//Mock för när api är nere, kan ta bort sen
extension APODState {
    static var mock: APODState {
        APODState(
            date: "2026-01-04",
            title: "Mock APOD — The Pillars of Creation",
            explanation: "This is placeholder data shown while the NASA APOD API is unavailable. Use it to design your layout, typography, and card spacing. Replace with live data automatically once the API comes back.",
            url: URL(string: "https://apod.nasa.gov")!,
            hdurl: URL(string: "https://images-assets.nasa.gov/image/PIA01322/PIA01322~orig.jpg")!,
            mediaType: "image"
        )
    }
}

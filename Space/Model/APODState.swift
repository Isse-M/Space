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
            explanation: "Towering columns of interstellar gas and dust rise from the heart of the Eagle Nebula in this iconic view known as the Pillars of Creation. These immense structures, each spanning several light-years, are sculpted by intense ultraviolet radiation and stellar winds from young, massive stars forming nearby. Within the dark, finger-like pillars, dense knots of gas collapse under gravity, giving birth to new stars hidden from visible light. First captured by the Hubble Space Telescope and later revisited by the James Webb Space Telescope in infrared light, the Pillars of Creation offer a dramatic glimpse into the ongoing cycle of star formation and destruction within our galaxy.",
            url: URL(string: "https://apod.nasa.gov")!,
            hdurl: URL(string: "https://images-assets.nasa.gov/image/PIA01322/PIA01322~orig.jpg")!,
            mediaType: "image"
        )
    }
}

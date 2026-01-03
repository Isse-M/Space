//
//  VisiblePlanetsResponse.swift
//  Space
//
//  Created by Ismail Mohammed on 2026-01-03.
//

import Foundation

struct VisiblePlanetsResponse: Decodable {
    let meta: Meta
    let data: [VisibleBody]
    let links: Links?

    struct Meta: Decodable {
        let time: String
        let engineVersion: String
        let latitude: Double
        let longitude: Double
        let elevation: Double
        let aboveHorizon: Bool
    }

    struct Links: Decodable {
        let `self`: String?
        let engine: String?
    }
}

struct VisibleBody: Decodable, Identifiable {
    // API:t skickar inget "id" i datan du fick, så vi använder name som id.
    // (Det är unikt i listan: Moon, Jupiter, Saturn, osv.) [page:0]
    var id: String { name }

    let name: String
    let constellation: String?

    let rightAscension: RightAscension?
    let declination: Declination?

    let altitude: Double
    let azimuth: Double
    let aboveHorizon: Bool

    let phase: Double?          // Moon har phase i din respons
    let magnitude: Double?
    let nakedEyeObject: Bool?

    struct RightAscension: Decodable {
        let negative: Bool
        let hours: Int
        let minutes: Int
        let seconds: Double
        let raw: Double
    }

    struct Declination: Decodable {
        let negative: Bool
        let degrees: Int
        let arcminutes: Int
        let arcseconds: Double
        let raw: Double
    }
}

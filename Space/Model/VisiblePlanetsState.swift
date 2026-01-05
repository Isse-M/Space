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
    var id: String { name }

    let name: String
    let constellation: String?

    let altitude: Double
    let azimuth: Double
    let aboveHorizon: Bool

    let phase: Double?          
    let magnitude: Double?
    let nakedEyeObject: Bool?
}

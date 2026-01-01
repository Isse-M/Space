//
//  ISSState.swift
//  Space
//
//  Created by Ismail Mohammed on 2026-01-01.
//


import Foundation

struct ISSState: Decodable, Equatable, Identifiable {
    let name: String
    let id: Int

    let latitude: Double
    let longitude: Double
    let altitude: Double
    let velocity: Double
    let visibility: String?

    let footprint: Double?
    let timestamp: TimeInterval
    let units: String
}

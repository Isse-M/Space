//
//  ISSState.swift
//  Space
//
//  Created by Ismail Mohammed on 2026-01-01.
//


import Foundation

struct ISSState: Decodable, Equatable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let velocity: Double

    let timestamp: TimeInterval
}

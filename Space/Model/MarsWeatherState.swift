//
//  MarsWeatherState.swift
//  Space
//
//  Created by Max Masuch on 2026-01-03.
//

import Foundation

struct MarsWeatherResponse: Decodable, Equatable {
    let solKeys: [String]
    let sols: [String: MarsSolWeather]

    private struct DynamicKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)

        // decode sol_keys
        let solKeysKey = DynamicKey(stringValue: "sol_keys")!
        self.solKeys = (try? container.decode([String].self, forKey: solKeysKey)) ?? []

        // decode only sols in sol_keys
        var tmp: [String: MarsSolWeather] = [:]
        for sol in solKeys {
            if let key = DynamicKey(stringValue: sol),
               let solData = try? container.decode(MarsSolWeather.self, forKey: key) {
                tmp[sol] = solData
            }
        }
        self.sols = tmp
    }

    var latest: MarsWeatherState? {
        guard let last = solKeys.last, let data = sols[last] else { return nil }
        return MarsWeatherState(sol: last, data: data)
    }
}

extension MarsWeatherResponse {
    var days: [MarsWeatherState] {
        solKeys.compactMap { sol in
            guard let data = sols[sol] else { return nil }
            return MarsWeatherState(sol: sol, data: data)
        }
    }
}


struct MarsWeatherState: Equatable, Identifiable {
    var id: String { sol }

    let sol: String
    let data: MarsSolWeather
}

struct MarsSolWeather: Decodable, Equatable {
    let firstUTC: String?
    let lastUTC: String?
    let season: String?

    let at: MarsMeasurement?   // Air temp
    let pre: MarsMeasurement?  // Pressure
    let hws: MarsMeasurement?  // Horizontal wind speed

    enum CodingKeys: String, CodingKey {
        case firstUTC = "First_UTC"
        case lastUTC  = "Last_UTC"
        case season   = "Season"
        case at       = "AT"
        case pre      = "PRE"
        case hws      = "HWS"
    }
}

struct MarsMeasurement: Decodable, Equatable {
    let av: Double?
    let mn: Double?
    let mx: Double?
}


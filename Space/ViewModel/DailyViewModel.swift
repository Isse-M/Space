//
//  DailyViewModel.swift
//  Space
//
//  Created by Max Masuch on 2026-01-03.
//

import Foundation
import Observation

@MainActor
@Observable
final class DailyViewModel {
    private let apodService: APODServicing
    private let marsService: MarsWeatherServicing
    private let rocketLaunchService: RocketLaunchServicing

    var apod: APODState?
    var mars: MarsWeatherState?
    
    var marsLatest: MarsWeatherState?
    var marsDays: [MarsWeatherState] = []

    var rocketLaunches: [RocketLaunchState] = []

    var isLoading = false
    var errorMessage: String?

    init(
        apodService: APODServicing = APODService(),
        marsService: MarsWeatherServicing = MarsWeatherService(),
        rocketLaunchService: RocketLaunchServicing = RocketLaunchService()
    ) {
        self.apodService = apodService
        self.marsService = marsService
        self.rocketLaunchService = rocketLaunchService
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        var errors: [String] = []

        let apodTask = Task { () -> APODState in
            try await apodService.fetchAPOD()
        }

        let marsTask = Task { () -> MarsWeatherResponse in
            try await marsService.fetchMarsWeather()
        }

        let launchesTask = Task { () -> [RocketLaunchState] in
            try await rocketLaunchService.fetchNextLaunches(limit: 5)
        }

        do {
            let marsRes = try await marsTask.value
            marsLatest = marsRes.latest
            marsDays = marsRes.days
            mars = marsRes.latest
        } catch {
            marsLatest = nil
            marsDays = []
            mars = nil
            errors.append("Mars: \(error.localizedDescription)")
        }

        do {
            let launchesRes = try await launchesTask.value
            rocketLaunches = Array(launchesRes.prefix(3))
        } catch {
            rocketLaunches = []
            errors.append("Launches: \(error.localizedDescription)")
        }

        do {
            apod = try await apodTask.value
        } catch {
            apod = nil
            errors.append("APOD: \(error.localizedDescription)")
        }

        errorMessage = errors.isEmpty ? nil : errors.joined(separator: " • ")
        isLoading = false
    }

    var marsTitle: String {
        guard let mars else { return "Marsväder" }
        return "Marsväder (Sol \(mars.sol))"
    }

    var marsTempText: String {
        guard let m = mars?.data.at else { return "—" }
        return formatMeasurement(m, suffix: "°C")
    }

    var marsPressureText: String {
        guard let m = mars?.data.pre else { return "—" }
        return formatMeasurement(m, suffix: "Pa")
    }

    var marsWindText: String {
        guard let m = mars?.data.hws else { return "—" }
        return formatMeasurement(m, suffix: "m/s")
    }

    var marsHeroSolText: String {
        "Sol \(marsLatest?.sol ?? "—")"
    }

    var marsHeroEarthDateText: String {
        earthDateText(from: marsLatest?.data.firstUTC)
    }

    var marsHeroHighLowText: String {
        let hi = marsLatest?.data.at?.mx.map { String(format: "%.0f°C", $0) } ?? "—"
        let lo = marsLatest?.data.at?.mn.map { String(format: "%.0f°C", $0) } ?? "—"
        return "High: \(hi)   Low: \(lo)"
    }

    private func formatMeasurement(_ m: MarsMeasurement, suffix: String) -> String {
        if let av = m.av { return String(format: "%.1f %@", av, suffix) }
        if let mn = m.mn, let mx = m.mx { return String(format: "%.1f–%.1f %@", mn, mx, suffix) }
        if let mn = m.mn { return String(format: "%.1f %@ (min)", mn, suffix) }
        if let mx = m.mx { return String(format: "%.1f %@ (max)", mx, suffix) }
        return "—"
    }

    func earthDateText(from firstUTC: String?) -> String {
        guard let firstUTC else { return "—" }

        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]

        let date = f1.date(from: firstUTC) ?? f2.date(from: firstUTC)
        guard let date else { return "—" }

        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    func launchDateText(_ launch: RocketLaunchState) -> String {
        if let iso = launch.winOpen ?? launch.t0,
           let date = parseISO(iso) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return "\(launch.dateStr) (estimated)"
    }

    private func parseISO(_ s: String) -> Date? {
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]

        return f1.date(from: s) ?? f2.date(from: s)
    }
}

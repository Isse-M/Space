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
    private let spacexService: SpaceXLaunchServicing
    private var lastLoadedAt: Date?

    var apod: APODState?
    var mars: MarsWeatherState?
    
    var marsLatest: MarsWeatherState?
    var marsDays: [MarsWeatherState] = []
    
    var spacexLaunches: [SpaceXLaunch] = []
    private var countdownTask: Task<Void, Never>?
    var now: Date = .now

    var isLoading = false
    var errorMessage: String?

    init(
        apodService: APODServicing = APODService(),
        marsService: MarsWeatherServicing = MarsWeatherService(),
        spacexService: SpaceXLaunchServicing = SpaceXLaunchService()
    ) {
        self.apodService = apodService
        self.marsService = marsService
        self.spacexService = spacexService
    }

    func load() async {
        if let last = lastLoadedAt,
           Date().timeIntervalSince(last) < 60 {
            return
        }
        lastLoadedAt = Date()
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            apod = try await apodService.fetchAPOD()
        } catch {
            errorMessage = "APOD: \(error.localizedDescription)"
        }
        
        do {
            let marsResult = try await marsService.fetchMarsWeather()
            marsLatest = marsResult.latest
            marsDays = marsResult.days
            mars = marsResult.latest
        } catch {
            let marsErr = "Mars: \(error.localizedDescription)"
            if let existing = errorMessage, !existing.isEmpty {
                errorMessage = existing + " • " + marsErr
            } else {
                errorMessage = marsErr
            }
        }
        do {
            let launches = try await spacexService.fetchUpcomingLaunches()
            let now = Date()
            let futureLaunches = launches
                .filter { $0.dateUTC > now }
                .sorted { $0.dateUTC < $1.dateUTC }
            spacexLaunches = futureLaunches
            print("Future SpaceX launches:", futureLaunches.count)
        } catch {
            let msg = "SpaceX: \(error.localizedDescription)"
            errorMessage = errorMessage == nil ? msg : errorMessage! + " • " + msg
        }
        if apod != nil, mars != nil {
            errorMessage = nil
        }
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
    
    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

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
    
    var next3Launches: [SpaceXLaunch] {
        Array(spacexLaunches.prefix(3))
    }

    func countdownText(to date: Date) -> String {
        let diff = Int(date.timeIntervalSince(now))
        if diff <= 0 { return "Liftoff!" }

        let days = diff / 86_400
        let hours = (diff % 86_400) / 3_600
        let minutes = (diff % 3_600) / 60
        let seconds = diff % 60

        if days > 0 {
            return String(format: "%dd %02dh %02dm %02ds", days, hours, minutes, seconds)
        } else {
            return String(format: "%02dh %02dm %02ds", hours, minutes, seconds)
        }
    }

    private func startCountdown() {
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                self.now = .now
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
}




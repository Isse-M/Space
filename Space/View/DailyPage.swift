//
//  DailyPage.swift
//  Space
//
//  Created by Max Masuch on 2026-01-03.
//

import SwiftUI

struct DailyPage: View {
    @State private var vm = DailyViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                Text("NASA APOD")
                    .font(.title2).bold()

                if vm.isLoading {
                    ProgressView()
                }

                if let apod = vm.apod {
                    apodCard(apod)
                }

                Text("Mars Weather")
                    .font(.title2).bold()

                marsWeatherSection
                
                Text("SpaceX Launches")
                    .font(.title2).bold()

                spacexSection

                if let err = vm.errorMessage {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    @ViewBuilder
    private func apodCard(_ apod: APODState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(apod.title)
                .font(.headline)

            Text(apod.date)
                .font(.caption)
                .foregroundStyle(.secondary)

            if apod.isImage {
                AsyncImage(url: apod.hdurl ?? apod.url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                            .clipped()
                    case .failure:
                        Text("Failed to load image.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Link("Open today’s APOD", destination: apod.url)
                    .font(.headline)
            }

            Text(apod.explanation)
                .font(.body)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var marsWeatherSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            marsHeroCard
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(vm.marsDays.suffix(7)) { day in
                        marsDayTile(day)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var marsHeroCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.marsHeroSolText)
                        .font(.title).bold()

                    Text(vm.marsHeroEarthDateText)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(vm.marsHeroHighLowText)
                    .font(.headline)
                    .multilineTextAlignment(.trailing)
            }

            HStack {
                marsStat("Temp", vm.marsTempText)
                marsStat("Tryck", vm.marsPressureText)
                marsStat("Vind", vm.marsWindText)
            }

            if vm.marsLatest == nil {
                Text("No Mars weather data available right now.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func marsDayTile(_ day: MarsWeatherState) -> some View {
        let dateText = vm.earthDateText(from: day.data.firstUTC)
        let hi = day.data.at?.mx.map { String(format: "%.0f°C", $0) } ?? "—"
        let lo = day.data.at?.mn.map { String(format: "%.0f°C", $0) } ?? "—"

        return VStack(alignment: .leading, spacing: 8) {
            Text("Sol \(day.sol)")
                .font(.headline)

            Text(dateText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider().opacity(0.4)

            Text("High: \(hi)")
                .font(.subheadline)

            Text("Low: \(lo)")
                .font(.subheadline)
        }
        .padding(12)
        .frame(width: 170, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func marsStat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var spacexSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if vm.next3Launches.isEmpty {
                Text("No upcoming launches found.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vm.next3Launches) { launch in
                    spacexLaunchCard(launch)
                }
            }
        }
    }

    private func spacexLaunchCard(_ launch: SpaceXLaunch) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(launch.name)
                .font(.headline)

            Text(launch.dateUTC.formatted(date: .abbreviated, time: .standard))
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text("T- \(vm.countdownText(to: launch.dateUTC))")
                    .font(.title3).bold()
                Spacer()
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

}

//
//  DailyPage.swift
//  Space
//
//  Created by Max Masuch on 2026-01-03.
//

import SwiftUI

struct DailyPage: View {
    @State private var vm = DailyViewModel()
    @State private var showAPODInfo = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                Text("NASA Astronomy Picture of the Day")
                    .font(.custom("Times New Roman", size: 32))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                if vm.isLoading {
                    ProgressView()
                }

                if let apod = vm.apod {
                    apodCard(apod)
                }
                
                sectionHeader("Mars Weather", imageName: "mars_icon")
                marsWeatherSection

                sectionHeader("Next Rocket Launches", imageName: "rocket_icon")
                rocketLaunchSection

                if let err = vm.errorMessage {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 48)
            .padding(.bottom, 90)
        }
        .background(backgroundView)
        .ignoresSafeArea()
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }
    
    private var backgroundView: some View {
        ZStack {
            Image("SpaceBG")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.35), .black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
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
                            .scaledToFill()
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

            Text(previewWords(apod.explanation, limit: 30))
                .font(.body)

            Button {
                showAPODInfo = true
            } label: {
                Label("More info", systemImage: "info.circle")
                    .font(.headline)
            }
            .padding(.top, 4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .sheet(isPresented: $showAPODInfo) {
            apodInfoSheet(apod)
        }
    }
    
    private func apodInfoSheet(_ apod: APODState) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(apod.title)
                        .font(.title2).bold()

                    Text(apod.date)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(apod.explanation)
                        .font(.body)
                }
                .padding()
            }
            .navigationTitle("APOD Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showAPODInfo = false }
                }
            }
        }
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
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
            Text("Low: \(lo)")
        }
        .font(.subheadline)
        .padding(12)
        .frame(width: 170, alignment: .leading)
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
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

    private var rocketLaunchSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if vm.rocketLaunches.isEmpty {
                    Text("No upcoming launches found.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vm.rocketLaunches) { launch in
                        rocketLaunchCard(launch)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rocketLaunchCard(_ launch: RocketLaunchState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.orange)
                    .font(.title3)

                Text(launch.name)
                    .font(.headline)
                    .lineLimit(2)
            }

            Text("\(launch.provider.name)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(launch.vehicle.name)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider().opacity(0.4)

            Text(vm.launchDateText(launch))
                .font(.body)
        }
        .padding(12)
        .frame(width: 240, alignment: .leading)
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }
    
    private func sectionHeader(_ title: String, imageName: String) -> some View {
        HStack(spacing: 8) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(.white.opacity(0.9))

            Text(title)
                .font(.custom("Times New Roman", size: 26))
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
    }
    private func previewWords(_ text: String, limit: Int = 30) -> String {
        let words = text.split(whereSeparator: \.isWhitespace)
        guard words.count > limit else { return text }
        return words.prefix(limit).joined(separator: " ") + "…"
    }

}

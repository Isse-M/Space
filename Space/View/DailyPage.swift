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
}

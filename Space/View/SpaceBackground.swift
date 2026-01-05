//
//  SpaceBackground.swift
//  Space
//
//  Created by Ismail Mohammed on 2026-01-05.
//

import SwiftUI

struct SpaceBackground: View {
    var body: some View {
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
}

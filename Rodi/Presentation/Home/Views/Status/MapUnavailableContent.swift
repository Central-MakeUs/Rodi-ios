//
//  MapUnavailableContent.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct MapUnavailableContent: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image("ic_network_inactive")
                .resizable()
                .frame(width: 60, height: 60)
                .accessibilityHidden(true)

            Text("지도를 불러올 수 없어요")
                .rodiTypography(.body1Medium)
                .foregroundStyle(RodiColor.black)

            Text(message)
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.gray700)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }
}

//
//  MapLoadingContent.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct MapLoadingContent: View {
    let kind: HomeLoadingKind

    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
                .controlSize(.regular)
                .tint(RodiColor.primary)

            Text(title)
                .rodiTypography(.body1Medium)
                .foregroundStyle(RodiColor.black)

            Text("잠시만 기다려주세요.")
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.gray700)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }

    private var title: String {
        "지도를 불러오고 있어요"
    }
}

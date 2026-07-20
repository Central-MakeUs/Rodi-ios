//
//  HomeResearchButton.swift
//  Rodi
//

import SwiftUI

struct HomeResearchButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .tint(RodiColor.white)
                        .frame(width: 18, height: 18)
                } else {
                    Image("ic_map_research")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }

                Text(isLoading ? "검색 중" : "재검색")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(height: 34)
            .background(Color(hex: 0x323232))
            .clipShape(Capsule())
            .shadow(color: RodiColor.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel("현재 지도에서 재검색")
    }
}

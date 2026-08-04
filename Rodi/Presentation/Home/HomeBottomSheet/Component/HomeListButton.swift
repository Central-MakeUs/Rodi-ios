//
//  HomeListButton.swift
//  Rodi
//

import SwiftUI

struct HomeListButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image("ic_list")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                Text("목록열기")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(Color(hex: 0x323232))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RodiColor.white)
            .clipShape(Capsule())
            .shadow(color: RodiColor.black.opacity(0.3), radius: 1.5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("연습코스 목록 열기")
    }
}

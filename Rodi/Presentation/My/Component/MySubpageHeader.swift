//
//  MySubpageHeader.swift
//  Rodi
//

import SwiftUI

struct MySubpageHeader: View {
    let title: String
    let backAction: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .rodiTypography(.headline1)
                .foregroundStyle(RodiColor.black)

            HStack {
                Button(action: backAction) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(RodiColor.black)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로가기")

                Spacer()
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
    }
}

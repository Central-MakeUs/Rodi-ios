//
//  RodiSnackbar.swift
//  Rodi
//

import SwiftUI

private struct RodiSnackbar: View {
    let message: String

    var body: some View {
        Text(message)
            .rodiTypography(.body3Medium)
            .foregroundStyle(RodiColor.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(RodiColor.black.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct RodiSnackbarModifier: ViewModifier {
    let message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                        RodiSnackbar(message: message)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 96)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: message)
    }
}

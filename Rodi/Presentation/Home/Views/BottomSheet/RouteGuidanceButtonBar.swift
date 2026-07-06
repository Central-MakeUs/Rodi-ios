//
//  RouteGuidanceButtonBar.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct RouteGuidanceButtonBar: View {
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .tint(RodiColor.white)
                    }

                    Text("경로 안내")
                        .rodiTypography(.buttonMedium)
                        .foregroundStyle(isEnabled ? RodiColor.white : RodiColor.gray500)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(isEnabled ? RodiColor.primary : RodiColor.gray300)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled || isLoading)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 20)
            .background(RodiColor.white)
        }
    }
}

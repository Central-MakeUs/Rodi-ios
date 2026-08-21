//
//  NetworkConnectionSnackbar.swift
//  Rodi
//

import SwiftUI

/// 네트워크 연결이 끊긴 동안 모든 화면에서 동일하게 노출하는 비차단 안내입니다.
struct NetworkConnectionSnackbar: View {
    let refreshAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image("ic_caution_round_white")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)

            Text("네트워크 연결이 원활하지 않아요.\n다시 시도해볼까요?")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.white)
                .lineLimit(2)

            Spacer(minLength: 8)

            Button(action: refreshAction) {
                Text("새로고침")
                    .rodiTypography(.caption2Medium)
                    .foregroundStyle(RodiColor.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RodiColor.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(RodiColor.black.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

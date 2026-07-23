//
//  NetworkRetryBanner.swift
//  Rodi
//

import SwiftUI

/// 사용자가 직접 재시도할 때까지 유지되는 지도 네트워크 오류 배너입니다.
struct NetworkRetryBanner: View {
    let retryAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image("ic_caution_round_white")
                .resizable()
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)

            Text("네트워크 연결 상태가 원활하지 않아요.\n다시 시도해볼까요?")
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            Button(action: retryAction) {
                Text("새로고침")
                    .rodiTypography(.caption2SemiBold)
                    .foregroundStyle(RodiColor.white)
                    .frame(width: 64, height: 30)
                    .background(RodiColor.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(RodiColor.black.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

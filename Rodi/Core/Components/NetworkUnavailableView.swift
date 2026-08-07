//
//  NetworkUnavailableView.swift
//  Rodi
//

import SwiftUI

struct NetworkUnavailableView: View {
    let refreshAction: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 8) {
                Image("ic_network_inactive")
                    .frame(width: 60, height: 60)

                Text("지도를 불러올 수 없어요")
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.gray800)

                Text("현재 위치 정보를 확인하기 위해\n네트워크 연결 상태를 확인해 주세요.")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray800)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.bottom, 72)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RodiColor.white)
        .safeAreaInset(edge: .bottom) {
            NetworkUnavailableToast(refreshAction: refreshAction)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
    }
}

private struct NetworkUnavailableToast: View {
    let refreshAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image("ic_caution_round_white")
                .frame(width: 24, height: 24)

            Text("네트워크 연결이 원활하지 않아요.\n다시 시도해볼까요?")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.white)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button(action: refreshAction) {
                Text("새로고침")
                    .rodiTypography(.caption2Medium)
                    .foregroundStyle(RodiColor.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RodiColor.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(RodiColor.gray800)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

//
//  NetworkUnavailableContent.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct NetworkUnavailableContent: View {
    let retryAction: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Image("ic_network_inactive")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .accessibilityHidden(true)

                Text("지도를 불러올 수 없어요")
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(RodiColor.black)

                Text("네트워크 연결이 원활하지 않아\n지도를 불러올 수 없어요.")
                    .rodiTypography(.caption1Medium)
                    .foregroundStyle(RodiColor.gray700)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            VStack {
                Spacer()
                NetworkRetryBanner(retryAction: retryAction)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 36)
            }
        }
    }
}

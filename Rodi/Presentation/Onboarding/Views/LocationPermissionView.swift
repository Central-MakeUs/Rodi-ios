//
//  LocationPermissionView.swift
//  Rodi
//

import SwiftUI

struct LocationPermissionView: View {
    let onAllow: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("현재 위치를 기반으로 주변 운전 연습 코스를\n추천하기 위해 위치정보를 사용합니다.")
                .rodiTypography(.headline2)
                .foregroundStyle(RodiColor.black)
                .multilineTextAlignment(.center)
                .padding(.top, 80)

            Image("ic_location_permission")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .padding(.vertical, 16)
                .accessibilityHidden(true)

            Text("내 주변 운전 연습 코스를 찾으려면\n위치 정보 허용이 꼭 필요해요.")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray800)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            PrimaryBottomButton(
                title: "계속하기",
                isEnabled: true,
                showsDivider: true,
                action: onAllow
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

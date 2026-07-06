//
//  LocationPermissionView.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct LocationPermissionView: View {
    let onAllow: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("현재 위치를 기반으로 주변 운전 연습 코스와\n주차장을 표시하기 위해 위치정보를 사용합니다.")
                .rodiTypography(.headline2)
                .foregroundStyle(RodiColor.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            Spacer()

            Image("ic_location_permission")
                .resizable()
                .frame(width: 200, height: 200)
                .accessibilityHidden(true)
                .offset(y: -70)

            Spacer()

            PrimaryBottomButton(title: "계속하기", isEnabled: true, action: onAllow)
        }
    }
}

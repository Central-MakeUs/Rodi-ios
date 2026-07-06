//
//  EmptyRadiusResultView.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct EmptyRadiusResultView: View {
    let showAllCoursesAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            Text("주변에서 추천할 수 있는 연습 코스를 찾지 못했어요.")
                .rodiTypography(.headline1)
                .foregroundStyle(RodiColor.gray800)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text("지도를 축소시켜, 전체 지역의\n연습 코스를 둘러보세요.")
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.gray800)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

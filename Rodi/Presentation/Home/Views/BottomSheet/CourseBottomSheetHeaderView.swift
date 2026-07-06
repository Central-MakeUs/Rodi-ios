//
//  CourseBottomSheetHeaderView.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct CourseBottomSheetHeaderView: View {
    let title: String
    let pageProgress: CGFloat
    let collapseAction: () -> Void

    var body: some View {
        ZStack {
            HStack {
                Text(title)
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.black)
                Spacer()
            }
            .opacity(1 - pageProgress)

            ZStack {
                Text(title)
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.black)

                HStack {
                    Button(action: collapseAction) {
                        Image(systemName: "chevron.left")
                            .font(.pretendard(size: 20, weight: .medium))
                            .foregroundStyle(RodiColor.black)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("연습코스 목록 접기")

                    Spacer()
                }
            }
            .opacity(pageProgress)
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
    }
}

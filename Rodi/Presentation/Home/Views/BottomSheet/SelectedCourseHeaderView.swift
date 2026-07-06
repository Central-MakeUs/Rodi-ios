//
//  SelectedCourseHeaderView.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct SelectedCourseHeaderView: View {
    let title: String
    let closeAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.black)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: closeAction) {
                Image(systemName: "xmark")
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundStyle(RodiColor.black)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("선택한 코스 닫기")
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }
}

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
    let filterAction: (() -> Void)?
    let closeAction: (() -> Void)?

    var body: some View {
        ZStack {
            HStack(spacing: 8) {
                if let closeAction {
                    Button(action: closeAction) {
                        Image(systemName: "chevron.left")
                            .font(.pretendard(size: 20, weight: .medium))
                            .foregroundStyle(RodiColor.black)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("필터 닫기")
                }

                Text(title)
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.black)
                Spacer()
                if let filterAction {
                    compactFilterButton(action: filterAction)
                }
            }
            .opacity(1 - pageProgress)

            ZStack {
                Text(title)
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.black)

                HStack {
                    Button(action: closeAction ?? collapseAction) {
                        Image(systemName: "chevron.left")
                            .font(.pretendard(size: 20, weight: .medium))
                            .foregroundStyle(RodiColor.black)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(closeAction == nil ? "연습코스 목록 접기" : "필터 닫기")

                    Spacer()

                    if let filterAction {
                        expandedFilterButton(action: filterAction)
                    }
                }
            }
            .opacity(pageProgress)
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
    }

    private func compactFilterButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image("ic_filter")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(RodiColor.black)
                .frame(width: 16, height: 16)
                .padding(3.5)
                .background(RodiColor.gray100)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .frame(width: 23, height: 23)
        .accessibilityLabel("추천 목록 필터")
    }

    private func expandedFilterButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image("ic_filter")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(RodiColor.black)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .frame(width: 24, height: 24)
        .accessibilityLabel("추천 목록 필터")
    }
}

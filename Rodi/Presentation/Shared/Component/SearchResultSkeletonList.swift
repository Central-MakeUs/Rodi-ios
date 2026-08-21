//
//  SearchResultSkeletonList.swift
//  Rodi
//

import SwiftUI

/// 검색 결과를 기다리는 동안 실제 목록과 같은 밀도로 보여주는 placeholder 행이다.
struct SearchResultSkeletonList: View {
    var count = 4

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { index in
                HStack(spacing: 12) {
                    Circle()
                        .fill(RodiColor.gray200)
                        .frame(width: 20, height: 20)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(RodiColor.gray200)
                        .frame(width: index.isMultiple(of: 2) ? 156 : 204, height: 16)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                .redacted(reason: .placeholder)
                .accessibilityHidden(true)

                Divider()
                    .overlay(RodiColor.primaryMinus100)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("검색 결과를 불러오는 중")
    }
}

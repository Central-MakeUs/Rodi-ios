//
//  HomeSearchEmptyState.swift
//  Rodi
//

import SwiftUI

struct HomeSearchEmptyState: View {
    let query: String?

    init(query: String? = nil) {
        self.query = query
    }

    var body: some View {
        if let query {
            VStack(spacing: 16) {
                Image("img_empty_radius_result")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)

                VStack(spacing: 8) {
                    Text("‘\(query)’ 검색 결과가 없어요.")
                        .rodiTypography(.headline1)

                    Text("검색어의 철자가 맞는지 확인해주세요.\n시/군/구/코스명으로 검색해주세요.")
                        .rodiTypography(.body3Medium)
                        .multilineTextAlignment(.center)
                }
            }
            .foregroundStyle(RodiColor.gray600)
            .frame(maxWidth: .infinity)
            .padding(.top, 138)
        } else {
            Text("최근 검색어가 없어요.")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray600)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 48)
        }
    }
}

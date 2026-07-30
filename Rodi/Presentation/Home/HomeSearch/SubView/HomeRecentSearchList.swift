//
//  HomeRecentSearchList.swift
//  Rodi
//

import SwiftUI

struct HomeRecentSearchList: View {
    let searches: [RecentSearch]
    let isLoading: Bool
    let selectAction: (RecentSearch) -> Void
    let deleteAction: (Int) -> Void
    let clearAllAction: () -> Void

    var body: some View {
        Group {
            if isLoading || !searches.isEmpty {
                recentSearchContent
            }
        }
    }

    private var recentSearchContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("최근 검색어")
                    .rodiTypography(.caption2Medium)
                    .foregroundStyle(RodiColor.gray700)

                Spacer()

                if !searches.isEmpty {
                    Button(action: clearAllAction) {
                        Text("전체 삭제")
                            .rodiTypography(.caption2Medium)
                            .foregroundStyle(RodiColor.gray500)
                    }
                        .buttonStyle(.plain)
                }
            }

            if isLoading {
                ProgressView()
                    .tint(RodiColor.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(searches) { search in
                        HStack(spacing: 12) {
                            Button {
                                selectAction(search)
                            } label: {
                                HStack(spacing: 10) {
                                    Image("ic_search")
                                        .resizable()
                                        .renderingMode(.template)
                                        .foregroundStyle(RodiColor.gray600)
                                        .frame(width: 20, height: 20)

                                    Text(search.keyword)
                                        .rodiTypography(.body1Medium)
                                        .foregroundStyle(RodiColor.gray800)
                                        .lineLimit(1)

                                    Spacer(minLength: 0)
                                }
                                .frame(maxWidth: .infinity, minHeight: 61, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                deleteAction(search.id)
                            } label: {
                                Image("ic_close")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundStyle(RodiColor.black)
                                    .frame(width: 20, height: 20)
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(search.keyword) 삭제")
                        }

                        Divider()
                            .overlay(RodiColor.primaryMinus100)
                    }
                }
            }
        }
    }
}

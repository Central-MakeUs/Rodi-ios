//
//  HomeRelatedSearchPlaceList.swift
//  Rodi
//

import SwiftUI

struct HomeRelatedSearchPlaceList: View {
    let suggestions: [PlaceRelatedSearchSuggestion]
    let isSearching: Bool
    let isLoadingNextPage: Bool
    let showsEmptyMessage: Bool
    let loadNextPage: () -> Void
    let selectAction: (PlaceRelatedSearchSuggestion) -> Void

    var body: some View {
        LazyVStack(spacing: 0) {
            if suggestions.isEmpty, !isSearching, showsEmptyMessage {
                Text("검색 결과가 없어요.")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 48)
            }

            ForEach(suggestions) { suggestion in
                Button {
                    selectAction(suggestion)
                } label: {
                    HStack(spacing: 12) {
                        Image("ic_map_pin")
                            .resizable()
                            .frame(width: 20, height: 20)

                        Text(suggestion.name)
                            .rodiTypography(.body1Medium)
                            .foregroundStyle(RodiColor.gray800)
                            .lineLimit(1)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(suggestion.name), \(suggestion.region) 상세 보기")

                Divider()
                    .overlay(RodiColor.primaryMinus100)
            }

            if isSearching || isLoadingNextPage {
                ProgressView()
                    .tint(RodiColor.primary)
                    .padding(.vertical, 20)
            } else if !suggestions.isEmpty {
                Color.clear
                    .frame(height: 1)
                    .onAppear(perform: loadNextPage)
            }
        }
    }
}

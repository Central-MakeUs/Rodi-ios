//
//  HomeSearchResultList.swift
//  Rodi
//

import SwiftUI

struct HomeSearchResultList: View {
    let results: [PlaceListItem]
    let isSearching: Bool
    let isLoadingNextPage: Bool
    let showsEmptyMessage: Bool
    let loadNextPage: () -> Void
    let selectAction: (PlaceListItem) -> Void

    var body: some View {
        LazyVStack(spacing: 0) {
            if results.isEmpty, !isSearching, showsEmptyMessage {
                Text("검색 결과가 없어요.")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 48)
            }

            ForEach(results) { item in
                HomeSearchResultRow(item: item) {
                    selectAction(item)
                }

                Divider()
                    .overlay(RodiColor.primaryMinus100)
            }

            if isSearching || isLoadingNextPage {
                ProgressView()
                    .tint(RodiColor.primary)
                    .padding(.vertical, 20)
            } else if !results.isEmpty {
                Color.clear
                    .frame(height: 1)
                    .onAppear(perform: loadNextPage)
            }
        }
    }
}

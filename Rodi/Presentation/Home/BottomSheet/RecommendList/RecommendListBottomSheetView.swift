//
//  RecommendListBottomSheetView.swift
//  Rodi
//

import SwiftUI

struct RecommendListBottomSheetView: View {
    let state: RecommendListBottomSheetReducer.State
    let send: (RecommendListBottomSheetReducer.Action) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if state.presentation == .expanded {
                expandedHeader
            } else if headerVisible {
                standardHeader
            }

            PlaceListView(
                items: state.items,
                isInitialLoading: state.isInitialLoading,
                isNextPageLoading: state.isNextPageLoading,
                errorMessage: state.errorMessage,
                hasNextPage: state.hasNext,
                isExpanded: state.presentation == .expanded,
                selectAction: { send(.select($0)) },
                reloadAction: { send(.reloadCurrentViewport(origin: nil)) },
                loadNextPageAction: { send(.loadNextPage) }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var headerVisible: Bool {
        state.presentation == .expanded || !state.items.isEmpty
    }

    private var standardHeader: some View {
        HStack {
            Text("추천 목록")
                .rodiTypography(.headline1)
            Spacer()
            filterButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    private var expandedHeader: some View {
        ZStack {
            Text("추천 목록")
                .rodiTypography(.headline1)

            HStack {
                Button(action: { send(.present) }) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(RodiColor.gray800)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("추천 목록 접기")

                Spacer()
                filterButton
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    private var filterButton: some View {
        Button(action: { send(.openFilter) }) {
            Image("ic_filter")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .modifier(FilterButtonStyle(isExpanded: state.presentation == .expanded))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel("필터 열기")
    }

}

private struct FilterButtonStyle: ViewModifier {
    let isExpanded: Bool

    func body(content: Content) -> some View {
        if isExpanded {
            content
        } else {
            content
                .frame(width: 23, height: 23)
                .background(Color(hex: 0xF5F5F5))
                .clipShape(Circle())
        }
    }
}

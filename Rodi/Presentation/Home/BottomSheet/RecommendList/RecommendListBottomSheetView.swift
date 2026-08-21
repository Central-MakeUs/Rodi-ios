//
//  RecommendListBottomSheetView.swift
//  Rodi
//

import SwiftUI

struct RecommendListBottomSheetView: View {
    let state: RecommendListBottomSheetReducer.State
    let send: (RecommendListBottomSheetReducer.Action) -> Void
    let debugReviewTestAction: () -> Void
    let debugHardWithdrawAction: () async throws -> Void
    let titlePanEnabled: Bool
    let titlePanChanged: (CGFloat) -> Void
    let titlePanEnded: (CGFloat) -> Void

    init(
        state: RecommendListBottomSheetReducer.State,
        send: @escaping (RecommendListBottomSheetReducer.Action) -> Void,
        debugReviewTestAction: @escaping () -> Void,
        debugHardWithdrawAction: @escaping () async throws -> Void,
        titlePanEnabled: Bool = false,
        titlePanChanged: @escaping (CGFloat) -> Void = { _ in },
        titlePanEnded: @escaping (CGFloat) -> Void = { _ in }
    ) {
        self.state = state
        self.send = send
        self.debugReviewTestAction = debugReviewTestAction
        self.debugHardWithdrawAction = debugHardWithdrawAction
        self.titlePanEnabled = titlePanEnabled
        self.titlePanChanged = titlePanChanged
        self.titlePanEnded = titlePanEnded
    }

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
                isAwaitingRegionViewport: state.isAwaitingRegionViewport,
                isRegionSearchResult: state.isRegionSearchResult,
                isNextPageLoading: state.isNextPageLoading,
                errorMessage: state.errorMessage,
                hasNextPage: state.hasNext,
                isExpanded: state.presentation == .expanded,
                selectAction: { send(.select($0)) },
                reloadAction: { send(.reloadCurrentViewport(origin: nil)) },
                loadNextPageAction: { send(.loadNextPage) },
                debugReviewTestAction: debugReviewTestAction,
                debugHardWithdrawAction: debugHardWithdrawAction
            )
            .overlay(alignment: .top) {
                if showsEmptyResultDragRegion {
                    emptyResultDragRegion
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var headerVisible: Bool {
        state.presentation == .expanded || !state.items.isEmpty
    }

    private var showsEmptyResultDragRegion: Bool {
        state.presentation != .expanded
            && state.items.isEmpty
            && !state.isInitialLoading
            && !state.isAwaitingRegionViewport
            && state.errorMessage == nil
    }

    private var emptyResultDragRegion: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .contentShape(Rectangle())
            .overlay {
                BottomSheetPanGestureView(
                    isEnabled: titlePanEnabled,
                    onChanged: titlePanChanged,
                    onEnded: titlePanEnded
                )
            }
            .accessibilityLabel("바텀 시트 크기 조절")
    }

    private var standardHeader: some View {
        HStack {
            HomeBottomSheetTitleDragRegion(
                isEnabled: titlePanEnabled,
                onChanged: titlePanChanged,
                onEnded: titlePanEnded
            ) {
                Text("추천 목록")
                    .rodiTypography(.headline1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            filterButton
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private var expandedHeader: some View {
        ZStack {
            HomeBottomSheetTitleDragRegion(
                isEnabled: titlePanEnabled,
                onChanged: titlePanChanged,
                onEnded: titlePanEnded
            ) {
                Text("추천 목록")
                    .rodiTypography(.headline1)
                    .padding(.horizontal, 24)
                    .frame(height: 56)
            }

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

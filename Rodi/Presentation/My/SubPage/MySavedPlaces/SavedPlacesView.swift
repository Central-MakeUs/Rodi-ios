//
//  SavedPlacesView.swift
//  Rodi
//

import SwiftUI

struct SavedPlacesView: View {
    @StateObject private var store: StoreOf<MySavedPlacesReducer>
    let selectPlaceAction: (PlaceListItem) -> Void
    let backAction: () -> Void

    init(
        placeRepository: PlaceRepository,
        backAction: @escaping () -> Void,
        selectPlaceAction: @escaping (PlaceListItem) -> Void = { _ in }
    ) {
        _store = StateObject(
            wrappedValue: Store(
                state: MySavedPlacesReducer.State(),
                reducer: MySavedPlacesReducer(placeRepository: placeRepository)
            )
        )
        self.backAction = backAction
        self.selectPlaceAction = selectPlaceAction
    }

    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "저장 목록", backAction: backAction)

            content
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            store.send(.appeared)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.state.isInitialLoading, store.state.items.isEmpty {
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if store.state.items.isEmpty {
            if let errorMessage = store.state.errorMessage {
                SavedPlacesErrorView(message: errorMessage) {
                    store.send(.retryTapped)
                }
            } else {
                SavedPlacesEmptyView()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    Text("\(store.state.totalCount ?? store.state.items.count)개")
                        .rodiTypography(.caption2Medium)
                        .foregroundStyle(RodiColor.gray700)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 8)

                    ForEach(store.state.items) { item in
                        PlaceListItemCard(item: item, selectAction: selectPlaceAction)

                        if item.id != store.state.items.last?.id {
                            Rectangle()
                                .fill(RodiColor.primaryMinus100)
                                .frame(height: 1)
                                .padding(.horizontal, 16)
                        }
                    }

                    if store.state.isNextPageLoading {
                        ProgressView()
                            .tint(RodiColor.primary)
                            .padding(.vertical, 20)
                    } else if let lastItem = store.state.items.last {
                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                store.send(.lastItemAppeared(lastItem))
                            }
                    }

                    if let errorMessage = store.state.errorMessage {
                        SavedPlacesErrorView(message: errorMessage) {
                            if store.state.items.last != nil {
                                store.send(.retryTapped)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct SavedPlacesEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RodiColor.primary50)
                    .frame(width: 60, height: 60)

                Image("ic_bookmark_action_filled")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundStyle(RodiColor.primary200)
                    .frame(width: 20, height: 24)
            }

            VStack(spacing: 8) {
                Text("저장한 코스가 없어요.")
                    .rodiTypography(.headline2)
                    .foregroundStyle(RodiColor.gray600)

                Text("홈에서 나에게 맞는 연습 코스를 찾아 저장해보세요.")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 104)
    }
}

private struct SavedPlacesErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(message)
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray700)

            Button(action: retry) {
                Text("다시 시도")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.primary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

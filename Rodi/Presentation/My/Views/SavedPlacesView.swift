//
//  SavedPlacesView.swift
//  Rodi
//

import SwiftUI

struct SavedPlacesView: View {
    @StateObject private var viewModel: SavedPlacesViewModel
    let selectPlaceAction: (PlaceListItem) -> Void

    init(
        placeRepository: PlaceRepository,
        selectPlaceAction: @escaping (PlaceListItem) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: SavedPlacesViewModel(placeRepository: placeRepository))
        self.selectPlaceAction = selectPlaceAction
    }

    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "저장 목록")

            content
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isInitialLoading, viewModel.items.isEmpty {
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.items.isEmpty {
            if let errorMessage = viewModel.errorMessage {
                SavedPlacesErrorView(message: errorMessage) {
                    Task { await viewModel.reload() }
                }
            } else {
                SavedPlacesEmptyView()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    Text("\(viewModel.totalCount ?? viewModel.items.count)개")
                        .rodiTypography(.caption2Medium)
                        .foregroundStyle(RodiColor.gray700)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 8)

                    ForEach(viewModel.items) { item in
                        PlaceListItemCard(item: item, selectAction: selectPlaceAction)

                        if item.id != viewModel.items.last?.id {
                            Rectangle()
                                .fill(RodiColor.primaryMinus100)
                                .frame(height: 1)
                                .padding(.horizontal, 16)
                        }
                    }

                    if viewModel.isNextPageLoading {
                        ProgressView()
                            .tint(RodiColor.primary)
                            .padding(.vertical, 20)
                    } else if let lastItem = viewModel.items.last {
                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                Task { await viewModel.loadNextPageIfNeeded(after: lastItem) }
                            }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        SavedPlacesErrorView(message: errorMessage) {
                            if let lastItem = viewModel.items.last {
                                Task { await viewModel.loadNextPageIfNeeded(after: lastItem) }
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

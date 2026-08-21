//
//  MyBlockedMembersView.swift
//  Rodi
//

import SwiftUI

struct MyBlockedMembersView: View {
    @StateObject private var store: StoreOf<MyBlockedMembersReducer>

    let backAction: () -> Void

    init(
        memberRepository: MemberRepository,
        backAction: @escaping () -> Void
    ) {
        _store = StateObject(
            wrappedValue: Store(
                state: MyBlockedMembersReducer.State(),
                reducer: MyBlockedMembersReducer(memberRepository: memberRepository)
            )
        )
        self.backAction = backAction
    }

    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "차단목록", backAction: backAction)
            content
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
        .rodiSnackbar(message: store.state.snackbarMessage)
        .task {
            store.send(.appeared)
        }
    }
}

// MARK: - Layout
private extension MyBlockedMembersView {

    @ViewBuilder
    var content: some View {
        if store.state.isInitialLoading, store.state.items.isEmpty {
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if store.state.items.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(store.state.items) { member in
                        BlockedMemberRow(
                            member: member,
                            isUnblocking: store.state.unblockingMemberIDs.contains(member.id),
                            unblockTapped: { store.send(.unblockTapped(memberID: member.id)) }
                        )
                        .onAppear {
                            store.send(.lastItemAppeared(member))
                        }
                    }

                    paginationFooter
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    var emptyState: some View {
        VStack(spacing: 12) {
            if let errorMessage = store.state.errorMessage {
                Text(errorMessage)
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(RodiColor.gray600)

                RodiRetryButton { store.send(.retryInitialTapped) }
            } else if store.state.hasCompletedInitialLoad {
                Text("차단한 사용자가 없습니다.")
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.gray600)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    var paginationFooter: some View {
        if store.state.isNextPageLoading {
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        } else if let errorMessage = store.state.errorMessage,
                  store.state.hasNextPage {
            VStack(spacing: 8) {
                Text(errorMessage)
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)

                RodiRetryButton { store.send(.retryNextPageTapped) }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
}

private struct BlockedMemberRow: View {
    let member: BlockedMember
    let isUnblocking: Bool
    let unblockTapped: () -> Void

    var body: some View {
        HStack {
            Text(member.displayNickname)
                .rodiTypography(.body1Medium)
                .foregroundStyle(RodiColor.black)
                .lineLimit(1)

            Spacer(minLength: 12)

            Button(action: unblockTapped) {
                HStack(spacing: 4) {
                    Image("ic_user_round")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)

                    if isUnblocking {
                        ProgressView()
                            .controlSize(.small)
                            .tint(RodiColor.informationCancel)
                            .frame(width: 20, height: 20)
                    } else {
                        Text("차단해제")
                            .rodiTypography(.caption2Medium)
                            .foregroundStyle(RodiColor.informationCancel)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RodiColor.informationCancelBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(isUnblocking)
            .accessibilityLabel("\(member.displayNickname) 차단 해제")
        }
        .frame(maxWidth: .infinity, minHeight: 28)
    }
}

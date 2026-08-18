import SwiftUI

struct MyPracticeRecordsView: View {
    @StateObject private var store: StoreOf<MyPracticeRecordsReducer>
    let backAction: () -> Void
    let reviewFlowFinishedRequestID: Int

    init(
        practiceRepository: PracticeRepository,
        reviewRequested: @escaping (ReviewWriteRequest) -> Void,
        reviewFlowFinishedRequestID: Int,
        backAction: @escaping () -> Void
    ) {
        _store = StateObject(
            wrappedValue: Store(
                state: MyPracticeRecordsReducer.State(),
                reducer: MyPracticeRecordsReducer(practiceRepository: practiceRepository)
            )
        )
        self.reviewRequested = reviewRequested
        self.reviewFlowFinishedRequestID = reviewFlowFinishedRequestID
        self.backAction = backAction
    }

    let reviewRequested: (ReviewWriteRequest) -> Void

    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "연습기록", backAction: backAction)
            content
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            store.send(.appeared)
        }
        .onChange(of: reviewFlowFinishedRequestID) { requestID in
            guard requestID > 0 else { return }
            store.send(.reloadRequested)
        }
    }
}

private extension MyPracticeRecordsView {

    @ViewBuilder
    var content: some View {
        if store.state.isInitialLoading, store.state.items.isEmpty {
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if store.state.items.isEmpty {
            MyPracticeRecordsEmptyState(errorMessage: store.state.errorMessage) {
                store.send(.retryTapped)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.state.items) { item in
                        MyPracticeRecordListRow(record: item, reviewRequested: reviewRequested)
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            .padding(.bottom, 20)

                        Rectangle()
                            .fill(RodiColor.primaryMinus100)
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                    }

                    paginationFooter
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    var paginationFooter: some View {
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
            VStack(spacing: 8) {
                Text(errorMessage)
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)
                Button(action: { store.send(.retryTapped) }) {
                    Text("다시 시도")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 16)
        }
    }
}

private struct MyPracticeRecordListRow: View {
    let record: MyPracticeItem
    let reviewRequested: (ReviewWriteRequest) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(record.placeName)
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text("\(record.visitCount)회차")
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.primary)
            }

            Text(dateText)
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.gray600)
                .padding(.top, 4)

            MyPracticeTypeChipRow(types: record.practiceTypes)
                .padding(.top, 4)

            if !record.isParkingPractice, !record.hasReview {
                Button {
                    reviewRequested(.init(placeID: record.placeID, placeName: record.placeName))
                } label: {
                    Text("후기 작성")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(RodiColor.primary, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(record.placeName) 후기 작성")
                .padding(.top, 16)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.placeName), \(dateText)")
    }

    private var dateText: String {
        guard let lastActivityAt = record.lastActivityAt else { return "방문 일자 없음" }
        return Self.dateFormatter.string(from: lastActivityAt)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yy.MM.dd"
        return formatter
    }()
}

private struct MyPracticeRecordsEmptyState: View {
    let errorMessage: String?
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if let errorMessage {
                Text(errorMessage)
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)
                Button(action: retry) {
                    Text("다시 시도")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.primary)
                }
                .buttonStyle(.plain)
            } else {
                Text("아직 연습기록이 없어요!")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)
                Text("가까운 연습 장소부터 천천히 시작해볼까요?")
                    .rodiTypography(.caption2Medium)
                    .foregroundStyle(RodiColor.gray600)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 104)
    }
}

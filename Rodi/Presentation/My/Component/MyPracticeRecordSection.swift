import SwiftUI

struct MyPracticeRecordSection: View {
    let records: [MyPracticeItem]
    let isLoading: Bool
    let hasCompletedInitialLoad: Bool
    let errorMessage: String?
    let openAll: () -> Void
    let retry: () -> Void
    let reviewRequested: (ReviewWriteRequest) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            content
        }
    }
}

private extension MyPracticeRecordSection {

    var header: some View {
        HStack(spacing: 0) {
            Text("연습기록")
                .rodiTypography(.body1Medium)
                .foregroundStyle(RodiColor.black)

            Spacer()

            if !records.isEmpty {
                Button(action: openAll) {
                    HStack(spacing: 2) {
                        Text("전체보기")
                            .rodiTypography(.body3Medium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(RodiColor.gray400)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("연습기록 전체보기")
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    var content: some View {
        if isLoading || !hasCompletedInitialLoad {
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 141)
        } else if let errorMessage {
            RodiRetryView(message: errorMessage, retryAction: retry)
            .frame(maxWidth: .infinity)
            .frame(height: 141)
        } else if records.isEmpty {
            MyPracticeRecordEmptyView()
                .frame(maxWidth: .infinity)
                .frame(height: 141)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(records) { record in
                        MyPracticeRecordPreviewCard(
                            record: record,
                            reviewRequested: reviewRequested
                        )
                    }
                }
                .padding(.leading, 16)
            }
            .accessibilityLabel("연습기록 \(records.count)개")
        }
    }
}

struct MyPracticeRecordPreviewCard: View {
    let record: MyPracticeItem
    let reviewRequested: (ReviewWriteRequest) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(record.placeName)
                .font(.pretendard(size: 15, weight: .semibold))
                .tracking(-0.3)
                .foregroundStyle(RodiColor.black)
                .lineLimit(1)

            Text(Self.dateFormatter.string(from: record.lastActivityAt))
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.gray600)
                .padding(.top, 4)

            MyPracticeTypeChipRow(types: record.practiceTypes)
                .padding(.top, 8)

            MyPracticeReviewStatus(
                hasReview: record.hasReview,
                isReviewWritable: !record.isParkingPractice,
                reviewRequested: { reviewRequested(.init(placeID: record.placeID, placeName: record.placeName)) }
            )
            .padding(.top, 12)
        }
        .padding(15)
        .frame(width: 179, height: 141, alignment: .topLeading)
        .background(RodiColor.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(RodiColor.primary50, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.placeName), \(Self.dateFormatter.string(from: record.lastActivityAt))")
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yy.MM.dd"
        return formatter
    }()
}

struct MyPracticeTypeChipRow: View {
    let types: [String]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(types.prefix(2)), id: \.self) { type in
                Text(PlacePracticeType.displayName(for: type))
                    .rodiTypography(.caption1Medium)
                    .foregroundStyle(RodiColor.gray600)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RodiColor.gray200)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }
        }
    }
}

struct MyPracticeReviewStatus: View {
    let hasReview: Bool
    let isReviewWritable: Bool
    let reviewRequested: () -> Void

    var body: some View {
        if !isReviewWritable {
            Text("작성 불가")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray500)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(RodiColor.gray300)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("주차 연습 후기는 작성할 수 없음")
        } else if hasReview {
            Text("작성 완료")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray500)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(RodiColor.gray300)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("후기 작성 완료")
        } else {
            Button(action: reviewRequested) {
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
        }
    }
}

private extension DateFormatter {

    func string(from date: Date?) -> String {
        guard let date else { return "방문 일자 없음" }
        return string(from: date)
    }
}

private struct MyPracticeRecordEmptyView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("아직 연습기록이 없어요!")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray600)

            Text("가까운 연습 장소부터 천천히 시작해볼까요?")
                .rodiTypography(.caption2Medium)
                .foregroundStyle(RodiColor.gray600)
        }
        .multilineTextAlignment(.center)
    }
}

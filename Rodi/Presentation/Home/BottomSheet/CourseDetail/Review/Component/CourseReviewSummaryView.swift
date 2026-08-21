import SwiftUI

struct CourseReviewSummaryView: View {
    let summary: PlaceReviewSummary
    let selectedLevel: ReviewLevelFilter
    @Binding var isLevelDropdownExpanded: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 30) {
            recommendSummary
                .padding(.leading, 32)
            Rectangle()
                .fill(RodiColor.gray300)
                .frame(width: 1, height: 48)
            difficultySummary
        }
    }

    private var recommendSummary: some View {
        VStack(spacing: 4) {
            Text("추천해요")
                .font(.pretendard(size: 15, weight: .semibold))
                .tracking(-0.3)
                .foregroundStyle(RodiColor.gray800)
                .lineLimit(1)

            HStack(spacing: 4) {
                Image("ic_thumbs_up")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text("\(summary.recommendCount)명")
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(1)
    }

    private var difficultySummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("난이도")
                    .font(.pretendard(size: 15, weight: .semibold))
                    .tracking(-0.3)
                    .foregroundStyle(RodiColor.gray800)

                Spacer(minLength: 0)

                levelPicker
            }

            HStack(spacing: 8) {
                if let difficulty = summary.topDifficulty {
                    Text(difficulty.title)
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.gray600)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RodiColor.gray200)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }

                Text("\(summary.topDifficultyCount)명")
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var levelPicker: some View {
        RodiDropdown(
            title: displayLevelName,
            anchorID: CourseReviewDropdown.summary,
            isExpanded: $isLevelDropdownExpanded
        )
        .accessibilityLabel("후기 레벨 \(displayLevelName)")
    }

    private var displayLevelName: String {
        summary.level?.displayName ?? selectedLevel.displayName
    }
}

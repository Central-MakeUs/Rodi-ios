import SwiftUI

struct CourseRegistrationSearchEmptyState: View {
    let query: String

    var body: some View {
        VStack(spacing: 12) {
            Image("img_empty_radius_result")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .accessibilityHidden(true)
                .padding(.bottom, 8)

            VStack(spacing: 8) {
                Text("‘\(trimmedQuery)’ 검색 결과가 없어요.")
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.gray700)

                Text("검색어의 철자가 맞는지 확인해주세요.\n장소 · 도로명으로 검색해주세요.")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct CourseRegistrationRecentSearchEmptyState: View {
    var body: some View {
        Text("최근 검색 내역이 없습니다")
            .rodiTypography(.body1Medium)
            .foregroundStyle(RodiColor.gray600)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .accessibilityLabel("최근 검색 내역이 없습니다")
    }
}

import SwiftUI

struct MyPostReviewRow: View {
    let review: MyReviewItem
    let isMenuExpanded: Bool
    let menuTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(review.placeName)
                    .font(.pretendard(size: 15, weight: .semibold))
                    .tracking(-0.3)
                    .foregroundStyle(RodiColor.black)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .trailing) {
                        Button(action: menuTapped) {
                            Image("ic_more_horizontal_circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .anchorPreference(key: RodiDropdownAnchorPreferenceKey.self, value: .bounds) {
                                    [AnyHashable("review-\(review.id)"): $0]
                                }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .accessibilityLabel(isMenuExpanded ? "후기 메뉴 닫기" : "후기 메뉴 열기")
                    }

                Text(Self.dateFormatter.string(from: review.createdAt))
                    .font(.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(RodiColor.gray600)
            }

            if !review.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(review.content)
                    .font(.pretendard(size: 13, weight: .regular))
                    .tracking(-0.26)
                    .foregroundStyle(RodiColor.gray700)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .frame(height: 37)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(RodiColor.gray200, lineWidth: 1)
                    }
            }
        }
    }
}

private extension MyPostReviewRow {

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yy.MM.dd"
        return formatter
    }()
}

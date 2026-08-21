import SwiftUI

struct CourseReviewCard: View {
    let review: PlaceReviewItem
    let level: ReviewLevel
    let onMoreTapped: (() -> Void)?

    init(
        review: PlaceReviewItem,
        level: ReviewLevel,
        onMoreTapped: (() -> Void)? = nil
    ) {
        self.review = review
        self.level = level
        self.onMoreTapped = onMoreTapped
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                RodiLevelProfileImage(
                    level: level,
                    size: 30,
                    backgroundColor: RodiColor.primary100,
                    cornerRadius: 15,
                    imageOffsetY: 0
                )

                Text(review.displayNickname)
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)

                Spacer(minLength: 0)

                Button {
                    onMoreTapped?()
                } label: {
                    Image("ic_more_horizontal")
                        .frame(width: 18, height: 30, alignment: .trailing)
                }
                .buttonStyle(.plain)
                .disabled(onMoreTapped == nil)
                .accessibilityLabel("후기 메뉴")
                .anchorPreference(key: RodiDropdownAnchorPreferenceKey.self, value: .bounds) {
                    [AnyHashable(CourseReviewDropdown.reviewMenu(review.id)): $0]
                }
            }

            HStack(spacing: 4) {
                if review.isVerifiedVisit {
                    CourseReviewBadge(title: "방문인증", style: .verified)
                }
                CourseReviewBadge(title: review.practiceMethodDisplayName, style: .practiceMethod)
            }

            VStack(alignment: .trailing, spacing: 6) {
                if !review.content.isEmpty {
                    Text(review.content)
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.gray800)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 0) {
                    Spacer(minLength: 0)

                    Text(review.createdAt.reviewDisplayDate)
                        .rodiTypography(.caption2Medium)
                        .foregroundStyle(RodiColor.gray500)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

private struct CourseReviewBadge: View {
    enum Style {
        case verified
        case practiceMethod
    }

    let title: String
    let style: Style

    var body: some View {
        Text(title)
            .rodiTypography(.caption2Medium)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(borderColor, lineWidth: 1)
            }
    }

    private var foregroundColor: Color {
        switch style {
        case .verified: RodiColor.primary
        case .practiceMethod: RodiColor.gray600
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .verified: RodiColor.primary100
        case .practiceMethod: RodiColor.gray50
        }
    }

    private var borderColor: Color {
        switch style {
        case .verified: RodiColor.primary200
        case .practiceMethod: RodiColor.gray200
        }
    }
}

private extension String {
    var reviewDisplayDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: self)
            ?? ISO8601DateFormatter().date(from: self)
            ?? dateWithoutTimeZone
        guard let date else { return self }
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "ko_KR_POSIX")
        displayFormatter.dateFormat = "yy.MM.dd"
        return displayFormatter.string(from: date)
    }

    private var dateWithoutTimeZone: Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        for format in [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss"
        ] {
            formatter.dateFormat = format
            if let date = formatter.date(from: self) {
                return date
            }
        }
        return nil
    }
}

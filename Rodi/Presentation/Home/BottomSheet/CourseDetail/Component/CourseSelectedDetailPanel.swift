//
//  CourseSelectedDetailPanel.swift
//  Rodi
//

import SwiftUI

struct CourseSelectedDetailPanel: View {
    let detail: PlaceDetail
    let isBookmarkUpdating: Bool
    let isRouteLoading: Bool
    let isRouteGuidanceEnabled: Bool
    let closeAction: () -> Void
    let bookmarkAction: () -> Void
    let routeGuidanceAction: () -> Void

    private var course: PlaceCourseDetail? { detail.course }
    private var visibleTags: [String] {
        Array(detail.practiceTypes.map(PlacePracticeType.displayName(for:)).prefix(4))
    }
    private var remainingTagCount: Int {
        max(0, detail.practiceTypes.count - visibleTags.count)
    }
    private var cautionText: String? {
        let cautions = Array((course?.cautions ?? []).prefix(2))
        return cautions.isEmpty ? nil : cautions.joined(separator: " ･ ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            content
            actionBar
        }
    }

    private var header: some View {
        HStack(spacing: 4) {
            Text(detail.name)
                .rodiTypography(.headline1)
                .foregroundStyle(RodiColor.black)
                .lineLimit(1)

            bookmarkCountLabel

            Spacer(minLength: 0)

            Button(action: closeAction) {
                Image("ic_close")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .frame(width: 23, height: 23)
                    .background(Color(hex: 0xF5F5F5))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .accessibilityLabel("선택한 코스 닫기")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var bookmarkCountLabel: some View {
        HStack(spacing: 2) {
            Image("ic_bookmark_count")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)

            Text("\(detail.bookmarkCount)")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray700)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                if let distanceMeters = course?.distanceMeters {
                    Text(formattedDistance(distanceMeters))
                        .rodiTypography(.body1SemiBold)
                        .foregroundStyle(RodiColor.primary)
                }

                Text("주행거리")
                    .rodiTypography(.caption1Medium)
                    .foregroundStyle(RodiColor.gray800)
            }

            if !visibleTags.isEmpty || remainingTagCount > 0 {
                HStack(spacing: 4) {
                    ForEach(visibleTags, id: \.self) { tag in
                        Text(tag)
                            .rodiTypography(.caption1Medium)
                            .foregroundStyle(RodiColor.gray600)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RodiColor.gray200)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            .lineLimit(1)
                    }

                    if remainingTagCount > 0 {
                        Text("+\(remainingTagCount)")
                            .rodiTypography(.caption1Medium)
                            .foregroundStyle(RodiColor.gray700)
                    }
                }
                .lineLimit(1)
            }

            if let cautionText {
                HStack(spacing: 4) {
                    Image("ic_alert_triangle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)

                    Text(cautionText)
                        .rodiTypography(.caption1Medium)
                        .lineLimit(1)
                }
                .foregroundStyle(RodiColor.secondary400)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }

            if let summary = course?.summary, !summary.isEmpty {
                Text(summary)
                    .rodiTypography(.caption1Regular)
                    .foregroundStyle(RodiColor.gray800)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 37)
                    .background(RodiColor.gray100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.bottom, 18)
            }
        }
        .padding(.horizontal, 16)
    }

    private var actionBar: some View {
        HStack(spacing: 5) {
            Button(action: bookmarkAction) {
                Group {
                    if isBookmarkUpdating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(detail.isBookmarked ? "ic_bookmark_action_filled" : "ic_bookmark_action")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                }
                .foregroundStyle(RodiColor.gray800)
                .frame(width: 46, height: 46)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(RodiColor.gray300, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(isBookmarkUpdating)
            .accessibilityLabel(detail.isBookmarked ? "북마크 해제" : "북마크 저장")

            Button(action: routeGuidanceAction) {
                HStack(spacing: 8) {
                    if isRouteLoading {
                        ProgressView()
                            .controlSize(.small)
                            .tint(RodiColor.white)
                    }
                    Text("연습하러 가기")
                        .rodiTypography(.buttonMedium)
                }
                .foregroundStyle(RodiColor.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(isRouteGuidanceEnabled ? RodiColor.primary : RodiColor.gray300)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(!isRouteGuidanceEnabled || isRouteLoading)
        }
        .padding(.horizontal, 16)
        .padding(.top, 0)
        .padding(.bottom, 36)
        .background(RodiColor.white)
    }

    private func formattedDistance(_ meters: Int) -> String {
        let kilometers = Double(meters) / 1_000
        if kilometers.rounded() == kilometers {
            return String(format: "%.0fkm", kilometers)
        }
        return String(format: "%.1fkm", kilometers)
    }
}

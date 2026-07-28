//
//  ParkingSelectedDetailPanel.swift
//  Rodi
//

import SwiftUI

/// Figma 604:21922, 604:22044 기준의 주차장 상세 패널.
/// 시트 높이는 상위 레이아웃 정책이 고정하고, 정보 영역만 스크롤한다.
struct ParkingSelectedDetailPanel: View {
    private enum ExpandedSection {
        case address
        case operatingHours
    }

    let detail: PlaceDetail
    let isBookmarkUpdating: Bool
    let isRouteLoading: Bool
    let isRouteGuidanceEnabled: Bool
    let closeAction: () -> Void
    let bookmarkAction: () -> Void
    let routeGuidanceAction: () -> Void

    @State private var expandedSection: ExpandedSection?

    private var parking: PlaceParkingDetail? { detail.parking }

    private var districtSummary: String {
        let parts = detail.address.split(separator: " ").map(String.init)
        return parts.count >= 2 ? parts.prefix(2).joined(separator: " ") : detail.address
    }

    private var operatingHoursSummary: String {
        guard let weekday = parking?.operatingHours?.weekday?.trimmedNonEmpty else {
            return "운영시간 정보 없음"
        }

        let separators = ["-", "~", "–", "—"]
        let startTime = separators
            .compactMap { weekday.components(separatedBy: $0).first?.trimmedNonEmpty }
            .first
            ?? weekday
        return "\(startTime)에 영업 시작"
    }

    private var feeRows: [ParkingDetailInfoRow] {
        let feeInfo = parking?.feeInfo
        return [
            ParkingDetailInfoRow(title: "초기무료", value: "해당항목없음"),
            ParkingDetailInfoRow(
                title: "기본요금",
                value: formattedFee(minutes: feeInfo?.baseMinutes, fee: feeInfo?.baseFee)
            ),
            ParkingDetailInfoRow(
                title: "추가요금",
                value: formattedFee(minutes: feeInfo?.addUnitMinutes, fee: feeInfo?.addUnitFee)
            ),
            ParkingDetailInfoRow(title: "할증기준시간", value: "해당항목없음")
        ]
    }

    private var operatingHourRows: [ParkingDetailInfoRow] {
        let hours = parking?.operatingHours
        let holiday = hours?.holiday?.trimmedNonEmpty ?? "해당항목없음"
        return [
            ParkingDetailInfoRow(title: "평일", value: hours?.weekday?.trimmedNonEmpty ?? "해당항목없음"),
            ParkingDetailInfoRow(title: "토요일", value: hours?.saturday?.trimmedNonEmpty ?? "해당항목없음"),
            ParkingDetailInfoRow(title: "일요일", value: holiday),
            ParkingDetailInfoRow(title: "공휴일", value: holiday)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    topInformation
                    Divider()
                        .overlay(RodiColor.primaryMinus100)
                        .padding(.vertical, 16)
                    feeInformation
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)

            actionBar
        }
        .background(RodiColor.white)
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
                Image(systemName: "xmark")
                    .font(.pretendard(size: 20, weight: .medium))
                    .foregroundStyle(RodiColor.gray800)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("선택한 주차장 닫기")
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
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

    private var topInformation: some View {
        VStack(alignment: .leading, spacing: 8) {
            ParkingDetailToggleRow(
                title: districtSummary,
                isExpanded: expandedSection == .address,
                action: { toggle(.address) }
            )

            if expandedSection == .address {
                ParkingAddressInformation(
                    roadAddress: parking?.roadAddress?.trimmedNonEmpty ?? detail.address,
                    lotAddress: parking?.lotAddress?.trimmedNonEmpty
                )
                .padding(.top, 2)
            }

            ParkingDetailToggleRow(
                prefix: "주차",
                title: operatingHoursSummary,
                isExpanded: expandedSection == .operatingHours,
                action: { toggle(.operatingHours) }
            )

            if expandedSection == .operatingHours {
                ParkingDetailRows(rows: operatingHourRows)
                    .padding(.top, 6)
            }

            if let capacity = parking?.capacity {
                Text("총 주차 면수 ･ \(capacity)대")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray800)
                    .padding(.top, expandedSection == nil ? 0 : 2)
            }
        }
    }

    private var feeInformation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("요금 안내")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray800)

            ParkingDetailRows(rows: feeRows)
        }
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
        .padding(.bottom, 36)
        .background(RodiColor.white)
    }

    private func toggle(_ section: ExpandedSection) {
        withAnimation(.easeInOut(duration: 0.18)) {
            expandedSection = expandedSection == section ? nil : section
        }
    }

    private func formattedFee(minutes: Int?, fee: Int?) -> String {
        guard let minutes, let fee else { return "해당항목없음" }
        let formattedFee = NumberFormatter.localizedString(from: NSNumber(value: fee), number: .decimal)
        return "\(minutes)분 ･ \(formattedFee)원"
    }
}

private struct ParkingDetailToggleRow: View {
    let prefix: String?
    let title: String
    let isExpanded: Bool
    let action: () -> Void

    init(title: String, isExpanded: Bool, action: @escaping () -> Void) {
        prefix = nil
        self.title = title
        self.isExpanded = isExpanded
        self.action = action
    }

    init(prefix: String, title: String, isExpanded: Bool, action: @escaping () -> Void) {
        self.prefix = prefix
        self.title = title
        self.isExpanded = isExpanded
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let prefix {
                    Text(prefix)
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.gray600)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RodiColor.gray200)
                        .clipShape(RoundedRectangle(cornerRadius: 2))

                    Text("･")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.gray800)
                }

                Text(title)
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray800)
                    .lineLimit(1)

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.pretendard(size: 9, weight: .medium))
                    .foregroundStyle(RodiColor.gray800)
                    .frame(width: 14, height: 14)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ParkingAddressInformation: View {
    let roadAddress: String
    let lotAddress: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ParkingAddressLine(label: "도로명", value: roadAddress)
            if let lotAddress {
                ParkingAddressLine(label: "지번", value: lotAddress)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RodiColor.primary50)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(RodiColor.primary200, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ParkingAddressLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.gray600)

            Text(value)
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.gray800)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ParkingDetailInfoRow: Identifiable {
    let title: String
    let value: String

    var id: String { title }
}

private struct ParkingDetailRows: View {
    let rows: [ParkingDetailInfoRow]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(rows) { row in
                HStack(spacing: 8) {
                    Text(row.title)
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.gray800)
                        .fixedSize(horizontal: true, vertical: false)

                    ParkingDotLeader()

                    Text(row.value)
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.gray800)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
    }
}

private struct ParkingDotLeader: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let dash: CGFloat = 3
                let gap: CGFloat = 4
                var x: CGFloat = 0
                let y = proxy.size.height / 2

                while x < proxy.size.width {
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: min(x + dash, proxy.size.width), y: y))
                    x += dash + gap
                }
            }
            .stroke(RodiColor.gray300, lineWidth: 1)
        }
        .frame(height: 1)
        .frame(maxWidth: .infinity)
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

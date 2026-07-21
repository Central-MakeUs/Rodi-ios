//
//  PlaceListView.swift
//  Rodi
//

import SwiftUI

/// 현재 지도 뷰포트 안의 장소 목록을 커서 페이지 단위로 표시한다.
struct PlaceListView: View {
    let items: [PlaceListItem]
    let isInitialLoading: Bool
    let isNextPageLoading: Bool
    let errorMessage: String?
    let hasNextPage: Bool
    let isExpanded: Bool
    let selectAction: (PlaceListItem) -> Void
    let reloadAction: () -> Void
    let loadNextPageAction: () -> Void

    var body: some View {
        Group {
            if items.isEmpty, isInitialLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else if items.isEmpty, let errorMessage {
                PlaceListMessageView(message: errorMessage, actionTitle: "다시 시도", action: reloadAction)
            } else if items.isEmpty {
                PlaceListEmptyResultView(isExpanded: isExpanded)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            PlaceListItemCard(item: item, selectAction: selectAction)

                            if item.id != items.last?.id {
                                Rectangle()
                                    .fill(RodiColor.primaryMinus100)
                                    .frame(height: 2)
                                    .padding(.horizontal, 16)
                            }
                        }

                        if hasNextPage {
                            Color.clear
                                .frame(height: 1)
                                .onAppear(perform: loadNextPageAction)
                        }

                        if isNextPageLoading {
                            ProgressView()
                                .padding(.vertical, 20)
                        }

                        if let errorMessage {
                            PlaceListMessageView(
                                message: errorMessage,
                                actionTitle: "다시 시도",
                                action: loadNextPageAction
                            )
                            .padding(.vertical, 16)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

/// 홈 추천 목록과 마이 저장 목록에서 공유하는 장소 카드입니다.
struct PlaceListItemCard: View {
    let item: PlaceListItem
    var selectAction: ((PlaceListItem) -> Void)?

    var body: some View {
        Group {
            if let selectAction {
                Button {
                    selectAction(item)
                } label: {
                    cardContent
                }
            } else {
                cardContent
            }
        }
        .buttonStyle(.plain)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch item.type {
            case .course:
                courseContent
            case .parking:
                parkingContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var courseContent: some View {
        Group {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(item.name)
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if let distanceMeters = item.distanceMeters {
                    HStack(spacing: 2) {
                        Text(courseDistanceText(distanceMeters))
                            .rodiTypography(.body3Medium)
                            .foregroundStyle(RodiColor.primary)
                        Text("주행거리")
                            .rodiTypography(.body3Medium)
                            .foregroundStyle(RodiColor.gray700)
                    }
                    .fixedSize()
                }
            }

            if !item.practiceTypes.isEmpty {
                PlaceListTagRow(tags: item.practiceTypes)
            }

            if let summary = item.summary?.trimmingCharacters(in: .whitespacesAndNewlines), !summary.isEmpty {
                Text(summary)
                    .rodiTypography(.caption1Medium)
                    .foregroundStyle(RodiColor.gray700)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(RodiColor.gray50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var parkingContent: some View {
        Group {
            Text(item.name)
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.black)
                .lineLimit(1)

            Text(item.address)
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.gray700)
                .lineLimit(1)

            PlaceListParkingMetaRow(openTime: item.openTime)

            if let capacity = item.capacity {
                Text("총 주차 면수 · \(capacity.formatted())대")
                    .rodiTypography(.caption1Medium)
                    .foregroundStyle(RodiColor.gray700)
            }
        }
    }

    private func courseDistanceText(_ meters: Int) -> String {
        if meters >= 1_000 {
            let kilometers = Double(meters) / 1_000
            return kilometers.rounded() == kilometers
                ? "\(Int(kilometers))km"
                : "\(String(format: "%.1f", kilometers))km"
        }

        return "\(meters)m"
    }
}

private struct PlaceListParkingMetaRow: View {
    let openTime: String?

    private var normalizedOpenTime: String? {
        guard let openTime else { return nil }
        let value = openTime.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var body: some View {
        HStack(spacing: 4) {
            PlaceListTagRow(tags: [PlacePracticeType.parking.rawValue])

            if let normalizedOpenTime {
                Text("･")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray800)

                HStack(spacing: 0) {
                    Text(normalizedOpenTime)
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.primary)
                    Text("에 영업 시작")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.gray800)
                }
                .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(1)
    }
}

private struct PlaceListTagRow: View {
    let tags: [String]

    private var displayTags: [String] {
        tags.map(PlacePracticeType.displayName(for:))
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(displayTags.prefix(3)), id: \.self) { tag in
                Text(tag)
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

private struct PlaceListMessageView: View {
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Text(message)
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray700)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140)
    }
}

private struct PlaceListEmptyResultView: View {
    let isExpanded: Bool

    var body: some View {
        Group {
            if isExpanded {
                VStack {
                    Spacer(minLength: 0)
                    emptyContent
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 56)
            } else {
                VStack {
                    emptyContent
                    Spacer(minLength: 0)
                }
                .padding(.top, 68)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: isExpanded ? .infinity : nil)
    }

    private var emptyContent: some View {
        VStack(spacing: 16) {
            Image("img_empty_radius_result")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            VStack(spacing: 8) {
                Text("추천할 수 있는 연습 코스를 찾지 못했어요.")
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.gray600)
                    .multilineTextAlignment(.center)

                Text("지도를 축소시켜, 전체 지역의\n연습 코스를 둘러보세요.")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

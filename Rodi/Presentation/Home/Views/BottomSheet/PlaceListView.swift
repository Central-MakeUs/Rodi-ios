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
                PlaceListMessageView(message: "이 지도 범위에 표시할 장소가 없어요.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            PlaceListCard(item: item, selectAction: selectAction)

                            if item.id != items.last?.id {
                                Divider()
                                    .overlay(RodiColor.gray100)
                                    .padding(.leading, 16)
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

private struct PlaceListCard: View {
    let item: PlaceListItem
    let selectAction: (PlaceListItem) -> Void

    var body: some View {
        Button {
            selectAction(item)
        } label: {
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
        .buttonStyle(.plain)
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
                    .lineLimit(2)
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

            PlaceListTagRow(tags: ["주차"])

            if let openTime = item.openTime?.trimmingCharacters(in: .whitespacesAndNewlines), !openTime.isEmpty {
                Text("\(openTime)에 영업 시작")
                    .rodiTypography(.caption1Medium)
                    .foregroundStyle(RodiColor.gray700)
            }

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

private struct PlaceListTagRow: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(tags.prefix(3)), id: \.self) { tag in
                Text(tag)
                    .rodiTypography(.caption2SemiBold)
                    .foregroundStyle(RodiColor.gray700)
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

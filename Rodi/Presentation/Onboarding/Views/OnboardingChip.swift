//
//  OnboardingChip.swift
//  Rodi
//

import SwiftUI

struct OnboardingChip: View {
    let title: String
    let isSelected: Bool
    var selectionOrder: Int?
    let action: () -> Void

    private let selectedTextColor = Color(hex: 0x2600B1)

    var body: some View {
        Button(action: action) {
            Text(title)
                .rodiTypography(.body3Medium)
                .foregroundStyle(isSelected ? selectedTextColor : RodiColor.gray600)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? RodiColor.primary100 : RodiColor.white)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? RodiColor.primary : RodiColor.primary200, lineWidth: 1)
                }
                .overlay(alignment: .topTrailing) {
                    if let selectionOrder {
                        Text("\(selectionOrder)")
                            .font(.pretendard(size: 12, weight: .medium))
                            .foregroundStyle(RodiColor.white)
                            .frame(width: 20, height: 20)
                            .background(RodiColor.primary)
                            .clipShape(Circle())
                            .offset(x: 8, y: -8)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
    }
}

struct OnboardingChipFlow: Layout {
    var horizontalSpacing: CGFloat = 6
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangeSubviews(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrangeSubviews(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)

        for row in arrangement.rows {
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + row.y),
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> Arrangement {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Arrangement.Row] = []
        var currentItems: [Arrangement.Item] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let nextX = currentItems.isEmpty ? 0 : currentX + horizontalSpacing

            if nextX + size.width > maxWidth, !currentItems.isEmpty {
                rows.append(.init(y: currentY, height: currentRowHeight, items: currentItems))
                currentY += currentRowHeight + verticalSpacing
                currentItems = []
                currentX = 0
                currentRowHeight = 0
            }

            let itemX = currentItems.isEmpty ? 0 : currentX + horizontalSpacing
            currentItems.append(.init(index: index, x: itemX, size: size))
            currentX = itemX + size.width
            currentRowHeight = max(currentRowHeight, size.height)
        }

        if !currentItems.isEmpty {
            rows.append(.init(y: currentY, height: currentRowHeight, items: currentItems))
        }

        let width = proposal.width ?? rows.map { row in
            row.items.map { $0.x + $0.size.width }.max() ?? 0
        }.max() ?? 0
        let height = rows.last.map { $0.y + $0.height } ?? 0
        return Arrangement(size: CGSize(width: width, height: height), rows: rows)
    }

    private struct Arrangement {
        let size: CGSize
        let rows: [Row]

        struct Row {
            let y: CGFloat
            let height: CGFloat
            let items: [Item]
        }

        struct Item {
            let index: Int
            let x: CGFloat
            let size: CGSize
        }
    }
}

struct OnboardingSection<Content: View>: View {
    let title: String
    var trailing: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(title)
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)

                if let trailing {
                    Text(trailing)
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.gray600)
                }
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

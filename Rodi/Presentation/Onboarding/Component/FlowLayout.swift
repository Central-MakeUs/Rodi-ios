//
//  FlowLayout.swift
//  Rodi
//

import SwiftUI

/// 추천 태그처럼 폭이 다른 항목을 줄바꿈해 배치하는 가벼운 레이아웃입니다.
struct FlowLayout: Layout {
    var spacing: CGFloat = 0

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        return layout(maxWidth: maxWidth, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = layout(maxWidth: bounds.width, subviews: subviews)
        for (subview, point) in zip(subviews, result.positions) {
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func layout(maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        let width = positions.isEmpty ? 0 : min(maxWidth, max(0, x - spacing))
        return (CGSize(width: width, height: y + rowHeight), positions)
    }
}

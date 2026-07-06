//
//  CourseRouteTimelineView.swift
//  Rodi
//

import SwiftUI

struct CourseRouteTimelineView: View {
    let points: [RodiRouteOverlayPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                CourseRouteTimelineRow(
                    point: point,
                    label: label(for: point, at: index),
                    isLast: index == points.count - 1
                )
            }
        }
    }

    private func label(for point: RodiRouteOverlayPoint, at index: Int) -> String {
        switch point.role {
        case .start:
            "출발지"
        case .waypoint:
            "경유지 \(waypointNumber(at: index))"
        case .end:
            "도착지"
        }
    }

    private func waypointNumber(at index: Int) -> Int {
        points.prefix(index + 1).filter { $0.role == .waypoint }.count
    }
}

struct CourseRouteTimelineRow: View {
    let point: RodiRouteOverlayPoint
    let label: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(spacing: 0) {
                Circle()
                    .fill(pointColor)
                    .frame(width: 9, height: 9)
                    .padding(.top, 4)

                if !isLast {
                    Rectangle()
                        .fill(RodiColor.gray300)
                        .frame(width: 1, height: 12)
                        .padding(.top, 5)
                }
            }
            .frame(width: 12)

            Text(label)
                .rodiTypography(.caption1Medium)
                .foregroundStyle(labelColor)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(width: 58, alignment: .leading)

            Text(point.name)
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.gray900)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: isLast ? 21 : 28, alignment: .top)
    }

    private var pointColor: Color {
        switch point.role {
        case .start:
            Color(hex: 0x347BFF)
        case .waypoint:
            RodiColor.gray400
        case .end:
            Color(hex: 0xFF5B5B)
        }
    }

    private var labelColor: Color {
        switch point.role {
        case .start:
            Color(hex: 0x347BFF)
        case .waypoint:
            RodiColor.gray600
        case .end:
            Color(hex: 0xFF5B5B)
        }
    }
}

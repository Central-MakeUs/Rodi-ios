//
//  SelectedCourseDetailContent.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct SelectedCourseDetailContent: View {
    let item: RodiCourseItem
    let orderedPoints: [RodiRouteOverlayPoint]

    var body: some View {
        switch item.type {
            case .course:
                CourseDetailContent(item: item, orderedPoints: orderedPoints)

            case .parking, .single:
                SingleLocationDetailContent(item: item)
        }
    }
}

private struct CourseDetailContent: View {
    let item: RodiCourseItem
    let orderedPoints: [RodiRouteOverlayPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CourseDistanceRow(item: item)
            DetailTagStrip(item: item)
            CourseSummaryBox(text: item.summary)

            if !orderedPoints.isEmpty {
                CourseRouteTimelineView(points: orderedPoints)
                    .padding(.top, 3)
            }
        }
    }
}

private struct SingleLocationDetailContent: View {
    let item: RodiCourseItem

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CourseDistanceRow(item: item)
            DetailTagStrip(item: item)
            CourseSummaryBox(text: item.summary)

            DetailInfoSection(title: "주소") {
                Text(item.address)
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray800)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let parking = item.parking {
                ParkingDetailSection(parking: parking)
            }
        }
    }
}

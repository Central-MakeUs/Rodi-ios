//
//  SelectedCourseDetailContent.swift
//  Rodi
//
//  Created by mac on 7/1/26.
//

import SwiftUI

struct SelectedCourseDetailContent: View {
    let item: RodiCourseItem
    let orderedPoints: [RodiRouteOverlayPoint]

    var body: some View {
        switch item.type {
            case .course:
                CourseDetailContent(item: item, orderedPoints: orderedPoints)

            case .parking:
                SingleLocationDetailContent(item: item)
        }
    }
}

// MARK: 코스 상세 화면
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

// MARK: 단일 스팟 상세 화면
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

//
//  CourseDistanceRow.swift
//  Rodi
//

import SwiftUI

struct CourseDistanceRow: View {
    let item: RodiCourseItem

    var body: some View {
        if let distanceKm = item.distanceKm {
            Text("주행거리 ･ \(formatDistance(distanceKm))")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray800)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func formatDistance(_ distanceKm: Double) -> String {
        if distanceKm.rounded() == distanceKm {
            return String(format: "%.0fkm", distanceKm)
        }

        return String(format: "%.1fkm", distanceKm)
    }
}

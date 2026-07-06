//
//  RoutePointRow.swift
//  Rodi
//

import SwiftUI

struct RoutePointRow: View {
    let point: RodiRouteOverlayPoint

    var body: some View {
        HStack(spacing: 10) {
            Image(assetName)
                .resizable()
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(roleTitle)
                    .rodiTypography(.caption3Medium)
                    .foregroundStyle(RodiColor.gray600)
                Text(point.name)
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.black)
                    .lineLimit(1)
            }
        }
    }

    private var roleTitle: String {
        switch point.role {
        case .start:
            "출발"
        case .waypoint:
            "경유"
        case .end:
            "도착"
        }
    }

    private var assetName: String {
        switch point.role {
        case .start:
            "ic_start_pin"
        case .waypoint:
            "ic_parking_pin"
        case .end:
            "ic_arrival_pin"
        }
    }
}

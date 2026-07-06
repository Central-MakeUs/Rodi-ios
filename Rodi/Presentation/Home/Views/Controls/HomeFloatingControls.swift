//
//  HomeFloatingControls.swift
//  Rodi
//

import SwiftUI

struct LegalSettingsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape")
                .font(.pretendard(size: 18, weight: .semibold))
                .foregroundStyle(RodiColor.gray800)
                .frame(width: 40, height: 40)
                .background(RodiColor.white)
                .clipShape(Circle())
                .shadow(color: RodiColor.black.opacity(0.12), radius: 8, x: 0, y: 2)
        }
        .accessibilityLabel("설정")
    }
}

struct RadiusFilterControl: View {
    let selectedFilter: HomeRadiusFilter
    let selectAction: (HomeRadiusFilter) -> Void

    private let segmentWidths: [HomeRadiusFilter: CGFloat] = [
        .all: 60,
        .three: 64,
        .five: 64,
        .ten: 71
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HomeRadiusFilter.allCases, id: \.self) { filter in
                Button {
                    selectAction(filter)
                } label: {
                    Text(filter.title)
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(selectedFilter == filter ? RodiColor.white : RodiColor.gray800)
                        .frame(width: segmentWidths[filter, default: 64], height: 31)
                        .background(selectedFilter == filter ? RodiColor.primary : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .frame(width: 267, height: 39)
        .background(RodiColor.white)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(RodiColor.primary100, lineWidth: 1)
        )
        .shadow(color: RodiColor.black.opacity(0.12), radius: 8, x: 0, y: 2)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct CurrentLocationButton: View {
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(isActive ? "ic_my_location_active" : "ic_my_location_inactive")
                .resizable()
                .frame(width: 24, height: 24)
                .padding(8)
                .background(RodiColor.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.22), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("내 위치로 이동")
    }
}

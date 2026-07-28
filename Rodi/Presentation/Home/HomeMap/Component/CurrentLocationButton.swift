//
//  CurrentLocationButton.swift
//  Rodi
//

import SwiftUI

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
                .shadow(color: RodiColor.black.opacity(0.22), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("내 위치로 이동")
    }
}

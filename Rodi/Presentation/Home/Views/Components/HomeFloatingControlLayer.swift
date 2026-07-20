//
//  HomeFloatingControlLayer.swift
//  Rodi
//

import SwiftUI

struct HomeFloatingControlLayer: View {
    let isCurrentLocationActive: Bool
    let mapZoomLevel: Int
    let bottomInset: CGFloat
    let opacity: CGFloat
    let allowsHitTesting: Bool
    let isAccessibilityHidden: Bool
    let spacing: CGFloat
    let currentLocationAction: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()

                VStack(spacing: 6) {
                    #if DEBUG
                    // TODO: 줌레벨 라벨 (윤수)
                    Text("\(mapZoomLevel)")
                        .font(.pretendard(size: 13, weight: .semibold))
                        .foregroundStyle(RodiColor.gray800)
                        .frame(width: 32, height: 32)
                        .background(RodiColor.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
                        .accessibilityLabel("현재 지도 줌 레벨 \(mapZoomLevel)")
                    #endif

                    CurrentLocationButton(
                        isActive: isCurrentLocationActive,
                        action: currentLocationAction
                    )
                }
                .padding(.trailing, spacing)
            }
            .padding(.bottom, bottomInset)
        }
        .opacity(opacity)
        .allowsHitTesting(allowsHitTesting)
        .accessibilityHidden(isAccessibilityHidden)
        .zIndex(2)
    }
}

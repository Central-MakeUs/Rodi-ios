//
//  PracticeRouteProgress.swift
//  RodiPracticeLiveActivity
//

import SwiftUI

@available(iOS 16.1, *)
struct PracticeRouteProgress: View {
    let progress: Double
    let rabbitAssetName: String

    private let middleDotWidth: CGFloat = 18
    private let endDotWidth: CGFloat = 10
    private let preferredDotSpacing: CGFloat = 5
    private let profileSize: CGFloat = 30

    private var normalizedProgress: CGFloat {
        CGFloat(min(max(progress, 0), 1))
    }

    private var displayedProgress: CGFloat {
        0.1 + (normalizedProgress * 0.9)
    }

    var body: some View {
        GeometryReader { proxy in
            let routeWidth = max(proxy.size.width, 0)
            let travelledWidth = routeWidth * displayedProgress
            let markerOffset = min(
                max(travelledWidth - (profileSize / 2), 0),
                max(routeWidth - profileSize, 0)
            )

            ZStack(alignment: .topLeading) {
                VStack(spacing: 2) {
                    routeLine(width: routeWidth, travelledWidth: travelledWidth)
                        .frame(height: 12)

                    HStack {
                        Text("출발").foregroundStyle(PracticeActivityPalette.primary)
                        Spacer(minLength: 0)
                        Text("도착").foregroundStyle(PracticeActivityPalette.gray600)
                    }
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: routeWidth)
                }

                PracticeDrivingProfileMarker(rabbitAssetName: rabbitAssetName)
                    .offset(x: markerOffset, y: -9)
            }
        }
        .frame(height: 31)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("연습 진행 상태 \(Int((progress * 100).rounded()))퍼센트")
    }

    @ViewBuilder
    private func routeLine(width: CGFloat, travelledWidth: CGFloat) -> some View {
        let middleDotCount = self.middleDotCount(for: width)
        let dotSpacing = self.dotSpacing(for: width, middleDotCount: middleDotCount)

        ZStack(alignment: .leading) {
            HStack(spacing: dotSpacing) {
                Capsule()
                    .fill(PracticeActivityPalette.gray500)
                    .frame(width: endDotWidth, height: 6)

                ForEach(0..<middleDotCount, id: \.self) { _ in
                    Capsule()
                        .fill(PracticeActivityPalette.gray500)
                        .frame(width: middleDotWidth, height: 6)
                }

                Capsule()
                    .fill(PracticeActivityPalette.gray500)
                    .frame(width: endDotWidth, height: 6)
            }
            .frame(width: width)

            Capsule()
                .fill(PracticeActivityPalette.primary)
                .frame(width: travelledWidth, height: 6)
        }
    }

    private func middleDotCount(for width: CGFloat) -> Int {
        let availableWidth = width - (endDotWidth * 2)
        guard availableWidth > 0 else { return 0 }
        return max(
            0,
            Int(((availableWidth + preferredDotSpacing) / (middleDotWidth + preferredDotSpacing)).rounded(.down))
        )
    }

    private func dotSpacing(for width: CGFloat, middleDotCount: Int) -> CGFloat {
        let usedDotWidth = (endDotWidth * 2) + (middleDotWidth * CGFloat(middleDotCount))
        return max((width - usedDotWidth) / CGFloat(middleDotCount + 1), 0)
    }
}

@available(iOS 16.1, *)
private struct PracticeDrivingProfileMarker: View {
    let rabbitAssetName: String

    var body: some View {
        ZStack {
            PracticeActivityPalette.primary
            Image(rabbitAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .offset(y: 3)
                .accessibilityHidden(true)
        }
        .frame(width: 30, height: 30)
        .clipShape(Circle())
        .overlay { Circle().stroke(.white, lineWidth: 0.75) }
        .accessibilityHidden(true)
    }
}

//
//  PracticeLiveActivity.swift
//  RodiPracticeLiveActivity
//

import ActivityKit
import SwiftUI
import WidgetKit

private enum PracticeActivityPalette {
    static let primary = Color(hex: 0x5640FF)
    static let primary400 = Color(hex: 0x7062FF)
    static let primary100 = Color(hex: 0xDBD9FF)
    static let gray100 = Color(hex: 0xF5F5F5)
    static let gray500 = Color(hex: 0x9F9F9F)
    static let text = Color(hex: 0x222222)
    static let gray800 = Color(hex: 0x434343)
    static let gray600 = Color(hex: 0x767676)
}

private extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

@main
struct RodiPracticeLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            RodiPracticeLiveActivity()
        }
    }
}

@available(iOS 16.1, *)
struct RodiPracticeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PracticeLiveActivityAttributes.self) { context in
            PracticeActivityView(context: context)
                .activityBackgroundTint(PracticeActivityPalette.gray100)
                .activitySystemActionForegroundColor(PracticeActivityPalette.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(
                        PracticeActivityView.phaseTitle(for: context.state),
                        systemImage: PracticeActivityView.phaseIcon(for: context.state)
                    )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PracticeActivityView.phaseColor(for: context.state))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(compactValue(for: context.state))
                        .font(.caption.monospacedDigit().weight(.semibold))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    PracticeActivityView(context: context)
                }
            } compactLeading: {
                Image(systemName: context.state.phaseRawValue == "completed" ? "checkmark.circle.fill" : "car.fill")
                    .foregroundStyle(PracticeActivityPalette.primary400)
            } compactTrailing: {
                Text(compactValue(for: context.state))
                    .font(.caption2.monospacedDigit().weight(.semibold))
            } minimal: {
                Image(systemName: context.state.phaseRawValue == "completed" ? "checkmark" : "car.fill")
            }
            .keylineTint(PracticeActivityPalette.primary400)
        }
    }

    private func compactValue(for state: PracticeLiveActivityAttributes.ContentState) -> String {
        if state.phaseRawValue == "completed" {
            return "완료"
        }
        if state.phaseRawValue == "headingToCourse", let distance = state.distanceToCourseStartMeters {
            return PracticeActivityView.formattedDistance(distance)
        }
        return "\(Int((state.progress * 100).rounded()))%"
    }
}

@available(iOS 16.1, *)
private struct PracticeActivityView: View {
    let context: ActivityViewContext<PracticeLiveActivityAttributes>

    var body: some View {
        Group {
            switch context.state.phaseRawValue {
            case "headingToCourse":
                headingToCourseContent
            case "drivingCourse":
                drivingCourseContent
            case "completed":
                completionContent
            default:
                completionContent
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PracticeActivityPalette.gray100)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    static func formattedDistance(_ meters: Int) -> String {
        if meters >= 1_000 {
            return String(format: "%.1fkm", Double(meters) / 1_000)
        }
        return "\(meters)m"
    }

    private var headingToCourseContent: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                RodiLogoView()

                VStack(alignment: .leading, spacing: 4) {
                    Text("연습 코스로 이동하고 있어요")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PracticeActivityPalette.primary)
                    Text("코스에 도착하면 Rodi가 주행을 기록해 드릴게요.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PracticeActivityPalette.gray800)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.trailing, 68)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(context.attributes.rabbitAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .padding(.top, 11)
                .accessibilityHidden(true)
        }
    }

    private var drivingCourseContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                RodiLogoView()
                VStack(alignment: .leading, spacing: 4) {
                    (Text(context.attributes.courseName).foregroundColor(PracticeActivityPalette.primary)
                    + Text(" 코스 주행 중").foregroundColor(PracticeActivityPalette.text))
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                    Text("Rodi가 코스 주행을 확인하고 있어요.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PracticeActivityPalette.gray800)
                }
            }

            if context.attributes.placeTypeRawValue != "parking" {
                PracticeRouteProgress(
                    progress: context.state.progress,
                    rabbitAssetName: context.attributes.rabbitAssetName
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var completionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            RodiLogoView()
            VStack(alignment: .leading, spacing: 4) {
                Text("오늘의 운전연습을 완료했어요!")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(PracticeActivityPalette.primary)
                VStack(alignment: .leading, spacing: 0) {
                    Text("오늘도 한 걸음 성장했어요.")
                    Text("Rodi로 돌아가 기록을 남겨주세요.")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(PracticeActivityPalette.gray800)
            }
            Text("기록하러 가기")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(PracticeActivityPalette.primary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    static func phaseTitle(for state: PracticeLiveActivityAttributes.ContentState) -> String {
        switch state.phaseRawValue {
        case "headingToCourse": "연습코스로 이동 중"
        case "drivingCourse": "코스 주행 중"
        case "completed": "코스 주행 완료"
        default: "연습 기록 종료"
        }
    }

    static func phaseIcon(for state: PracticeLiveActivityAttributes.ContentState) -> String {
        switch state.phaseRawValue {
        case "headingToCourse": "location.fill"
        case "drivingCourse": "car.fill"
        case "completed": "checkmark.circle.fill"
        default: "stop.circle.fill"
        }
    }

    static func phaseColor(for state: PracticeLiveActivityAttributes.ContentState) -> Color {
        PracticeActivityPalette.primary
    }
}

@available(iOS 16.1, *)
private struct RodiLogoView: View {
    var body: some View {
        Image("ic_live_activity_rodi_logo")
            .resizable()
            .scaledToFit()
            .frame(width: 48, height: 15)
            .accessibilityLabel("로디")
    }
}

@available(iOS 16.1, *)
private struct PracticeRouteProgress: View {
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

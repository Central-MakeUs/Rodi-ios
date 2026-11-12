//
//  PracticeLiveActivity.swift
//  RodiPracticeLiveActivity
//

import ActivityKit
import SwiftUI
import WidgetKit

enum PracticeActivityPalette {
    static let primary = Color(hex: 0x5640FF)
    static let primary400 = Color(hex: 0x7062FF)
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
                .widgetURL(PracticeLiveActivityDeepLink.url(sessionID: context.attributes.sessionID))
                .activityBackgroundTint(PracticeActivityPalette.gray100)
                .activitySystemActionForegroundColor(PracticeActivityPalette.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: PracticeActivityView.phaseIcon(for: context.state))
                        Text(expandedPhaseTitle(for: context.state))
                    }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(PracticeActivityPalette.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.leading, 4)
                        .accessibilityLabel(PracticeActivityView.phaseTitle(for: context.state))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(compactValue(for: context.state))
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    PracticeDynamicIslandExpandedView(context: context)
                }
            } compactLeading: {
                Image(systemName: context.state.phase == .completed ? "checkmark.circle.fill" : "car.fill")
                    .foregroundStyle(PracticeActivityPalette.primary400)
            } compactTrailing: {
                Text(compactValue(for: context.state))
                    .font(.caption2.monospacedDigit().weight(.semibold))
            } minimal: {
                Image(systemName: context.state.phase == .completed ? "checkmark" : "car.fill")
            }
            .keylineTint(PracticeActivityPalette.primary400)
            .widgetURL(PracticeLiveActivityDeepLink.url(sessionID: context.attributes.sessionID))
        }
    }

    private func compactValue(for state: PracticeLiveActivityAttributes.ContentState) -> String {
        if state.phase == .completed {
            return "완료"
        }
        if state.phase == .headingToCourse, let distance = state.distanceToCourseStartMeters {
            return PracticeActivityView.formattedDistance(distance)
        }
        return "\(Int((state.progress * 100).rounded()))%"
    }

    private func expandedPhaseTitle(for state: PracticeLiveActivityAttributes.ContentState) -> String {
        switch state.phase {
        case .headingToCourse: "이동 중"
        case .drivingCourse: "주행 중"
        case .completed: "완료"
        }
    }
}

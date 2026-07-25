//
//  PracticeLiveActivity.swift
//  RodiPracticeLiveActivity
//

import ActivityKit
import SwiftUI
import WidgetKit

private enum PracticeActivityPalette {
    static let primary = Color(red: 0.337, green: 0.251, blue: 1)
    static let primary400 = Color(red: 0.439, green: 0.384, blue: 1)
    static let primary100 = Color(red: 0.859, green: 0.851, blue: 1)
    static let primary20 = Color(red: 0.957, green: 0.957, blue: 1)
    static let text = Color(red: 0.133, green: 0.133, blue: 0.133)
    static let secondaryText = Color(red: 0.384, green: 0.384, blue: 0.384)
    static let completed = Color(red: 0.133, green: 0.647, blue: 0.345)
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
                .activityBackgroundTint(PracticeActivityPalette.primary20)
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
                    .foregroundStyle(context.state.phaseRawValue == "completed" ? PracticeActivityPalette.completed : PracticeActivityPalette.primary400)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 8) {
                Text(context.attributes.courseName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PracticeActivityPalette.text)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Label(phaseTitle, systemImage: phaseIcon)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(phaseColor)
                    .lineLimit(1)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(metricValue)
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(phaseColor)
                    .contentTransition(.numericText())

                Text(metricDescription)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PracticeActivityPalette.secondaryText)
            }
            .lineLimit(1)

            PracticeProgressBar(progress: journeyProgress, color: phaseColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    static func formattedDistance(_ meters: Int) -> String {
        if meters >= 1_000 {
            return String(format: "%.1fkm", Double(meters) / 1_000)
        }
        return "\(meters)m"
    }

    private var metricValue: String {
        switch context.state.phaseRawValue {
        case "headingToCourse":
            guard let distance = context.state.distanceToCourseStartMeters else { return "-" }
            return Self.formattedDistance(distance)
        case "drivingCourse":
            return "\(Int((context.state.progress * 100).rounded()))%"
        case "completed":
            return "완료"
        default:
            return "종료"
        }
    }

    private var metricDescription: String {
        switch context.state.phaseRawValue {
        case "headingToCourse": "시작점까지 남음"
        case "drivingCourse": "코스 주행 중"
        case "completed": "연습 코스를 주행했어요"
        default: "연습 기록이 종료됐어요"
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
        state.phaseRawValue == "completed"
            ? PracticeActivityPalette.completed
            : PracticeActivityPalette.primary
    }

    private var phaseTitle: String { Self.phaseTitle(for: context.state) }

    private var phaseIcon: String { Self.phaseIcon(for: context.state) }

    private var phaseColor: Color { Self.phaseColor(for: context.state) }

    private var journeyProgress: Double {
        switch context.state.phaseRawValue {
        case "headingToCourse":
            return min(max(context.state.approachProgress, 0), 1) * 0.2
        case "drivingCourse":
            return 0.2 + (min(max(context.state.progress, 0), 1) * 0.8)
        case "completed":
            return 1
        default:
            return 0
        }
    }
}

@available(iOS 16.1, *)
private struct PracticeProgressBar: View {
    let progress: Double
    let color: Color

    var body: some View {
        ProgressView(value: min(max(progress, 0), 1), total: 1)
            .tint(color)
            .progressViewStyle(.linear)
            .frame(height: 8)
            .background(PracticeActivityPalette.primary100, in: Capsule())
            .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("연습 진행 상태 \(Int((progress * 100).rounded()))퍼센트")
    }
}

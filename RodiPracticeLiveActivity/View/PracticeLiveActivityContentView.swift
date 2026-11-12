//
//  PracticeLiveActivityContentView.swift
//  RodiPracticeLiveActivity
//

import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct PracticeDynamicIslandExpandedView: View {
    let context: ActivityViewContext<PracticeLiveActivityAttributes>

    var body: some View {
        Group {
            switch context.state.phase {
            case .headingToCourse:
                headingToCourseContent
            case .drivingCourse:
                drivingCourseContent
            case .completed:
                completionContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            PracticeActivityPalette.gray100,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }

    private var headingToCourseContent: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("연습 코스로 이동하고 있어요")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PracticeActivityPalette.primary)
                Text("코스에 도착하면 주행 기록을 시작해요.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(PracticeActivityPalette.gray800)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(context.attributes.rabbitAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .accessibilityHidden(true)
        }
    }

    private var drivingCourseContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            (Text(context.attributes.courseName).foregroundColor(PracticeActivityPalette.primary)
            + Text(" 코스 주행 중").foregroundColor(PracticeActivityPalette.text))
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text("Rodi가 코스 주행을 확인하고 있어요.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(PracticeActivityPalette.gray800)
                .lineLimit(1)

            ProgressView(value: min(max(context.state.progress, 0), 1))
                .tint(PracticeActivityPalette.primary)
                .scaleEffect(y: 0.65, anchor: .center)
                .accessibilityLabel("연습 진행 상태 \(Int((context.state.progress * 100).rounded()))퍼센트")
        }
    }

    private var completionContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("오늘의 운전연습을 완료했어요!")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PracticeActivityPalette.primary)
            Text("Rodi로 돌아가 연습 기록을 확인해 주세요.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(PracticeActivityPalette.gray800)
                .lineLimit(1)
        }
    }
}

@available(iOS 16.1, *)
struct PracticeActivityView: View {
    let context: ActivityViewContext<PracticeLiveActivityAttributes>

    var body: some View {
        Group {
            switch context.state.phase {
            case .headingToCourse:
                headingToCourseContent
            case .drivingCourse:
                drivingCourseContent
            case .completed:
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

    static func phaseTitle(for state: PracticeLiveActivityAttributes.ContentState) -> String {
        switch state.phase {
        case .headingToCourse: "연습코스로 이동 중"
        case .drivingCourse: "코스 주행 중"
        case .completed: "코스 주행 완료"
        }
    }

    static func phaseIcon(for state: PracticeLiveActivityAttributes.ContentState) -> String {
        switch state.phase {
        case .headingToCourse: "location.fill"
        case .drivingCourse: "car.fill"
        case .completed: "checkmark.circle.fill"
        }
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

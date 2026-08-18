//
//  CourseDetailBottomSheetView.swift
//  Rodi
//

import ActivityKit
import SwiftUI
import UIKit

struct ActiveCourseMeasurementDialogConfiguration {
    let courseName: String
    let continueAction: () -> Void
    let endAction: () -> Void
}

struct LiveActivityPermissionDialogConfiguration {
    let openRouteOnly: () -> Void
    let openSettings: () -> Void
}

struct RouteGuidanceAppDialogConfiguration {
    let mode: RouteGuidanceAppDialog.Mode
    let onceAction: (RouteGuidanceApp) -> Void
    let alwaysAction: (RouteGuidanceApp) -> Void
    let installAction: (RouteGuidanceApp) -> Void
}

struct CourseDetailBottomSheetView: View {
    private struct RouteGuidanceRequest {
        let app: RouteGuidanceApp
        let detail: PlaceDetail
    }

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    enum RenderingMode {
        case sheet
        case expanded
    }

    let state: CourseDetailBottomSheetReducer.State
    let send: (CourseDetailBottomSheetReducer.Action) -> Void
    let userLocation: RodiCoordinate?
    let hasLocationPermission: Bool
    let memberRepository: MemberRepository
    let requestLocationPermission: () -> Void
    let renderingMode: RenderingMode
    let expandedBackAction: () -> Void
    let presentActiveMeasurementDialog: (ActiveCourseMeasurementDialogConfiguration) -> Void
    let presentLiveActivityPermissionDialog: (LiveActivityPermissionDialogConfiguration) -> Void
    let presentRouteGuidanceDialog: (RouteGuidanceAppDialogConfiguration) -> Void

    @State private var settingsRequest: RouteGuidanceRequest?

    init(
        state: CourseDetailBottomSheetReducer.State,
        send: @escaping (CourseDetailBottomSheetReducer.Action) -> Void,
        userLocation: RodiCoordinate?,
        hasLocationPermission: Bool,
        memberRepository: MemberRepository,
        requestLocationPermission: @escaping () -> Void,
        renderingMode: RenderingMode = .sheet,
        expandedBackAction: @escaping () -> Void = {},
        presentActiveMeasurementDialog: @escaping (ActiveCourseMeasurementDialogConfiguration) -> Void = { _ in },
        presentLiveActivityPermissionDialog: @escaping (LiveActivityPermissionDialogConfiguration) -> Void = { _ in },
        presentRouteGuidanceDialog: @escaping (RouteGuidanceAppDialogConfiguration) -> Void = { _ in }
    ) {
        self.state = state
        self.send = send
        self.userLocation = userLocation
        self.hasLocationPermission = hasLocationPermission
        self.memberRepository = memberRepository
        self.requestLocationPermission = requestLocationPermission
        self.renderingMode = renderingMode
        self.expandedBackAction = expandedBackAction
        self.presentActiveMeasurementDialog = presentActiveMeasurementDialog
        self.presentLiveActivityPermissionDialog = presentLiveActivityPermissionDialog
        self.presentRouteGuidanceDialog = presentRouteGuidanceDialog
    }

    var body: some View {
        Group {
            if let detail = state.detail {
                if renderingMode == .sheet {
                    sheet(detail: detail)
                } else {
                    CourseDetailExpandedPage(
                        state: state,
                        send: send,
                        bookmarkAction: { send(.toggleBookmark) },
                        routeGuidanceAction: requestRouteGuidance,
                        expandedBackAction: expandedBackAction
                    )
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active, let request = settingsRequest else { return }
            settingsRequest = nil
            if areLiveActivitiesEnabled {
                beginTrackingAndOpenRouteGuidance(request)
            } else {
                openRouteOnly(request)
            }
        }
    }
}


// MARK: - Layout
extension CourseDetailBottomSheetView {

    private func sheet(detail: PlaceDetail) -> some View {
        VStack(spacing: 0) {
            CourseSelectedDetailPanel(
                detail: detail,
                isBookmarkUpdating: state.isBookmarkUpdating,
                isRouteLoading: state.isRouteLoading,
                isRouteGuidanceEnabled: detail.course?.waypoints.count ?? 0 >= 2,
                closeAction: { send(.dismiss) },
                bookmarkAction: { send(.toggleBookmark) },
                routeGuidanceAction: requestRouteGuidance
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }

    private func requestRouteGuidance() {
        guard hasLocationPermission else {
            requestLocationPermission()
            return
        }
        guard userLocation != nil else {
            send(.delegate(.showSnackbar("현재 위치를 확인한 뒤 다시 시도해주세요.")))
            return
        }
        switch RouteGuidanceService.shared.launchOption() {
        case .open(let app):
            guard let detail = state.detail else { return }
            startRouteGuidance(app, detail: detail)
        case .choose:
            presentRouteGuidanceDialog(routeGuidanceDialogConfiguration(mode: .choose))
        case .install:
            presentRouteGuidanceDialog(routeGuidanceDialogConfiguration(mode: .install))
        }
    }

    private func startRouteGuidance(_ app: RouteGuidanceApp, detail: PlaceDetail) {
        startRouteGuidance(.init(app: app, detail: detail))
    }

    private func startRouteGuidance(_ request: RouteGuidanceRequest) {
        guard !PracticeTrackingService.shared.hasActiveMeasurement else {
            presentActiveMeasurementDialog(
                .init(
                    courseName: PracticeTrackingService.shared.session?.courseName ?? "현재 코스",
                    continueAction: {},
                    endAction: {
                        PracticeTrackingService.shared.cancel()
                        self.send(.activeMeasurementEnded)
                        self.startRouteGuidance(request)
                    }
                )
            )
            return
        }

        guard areLiveActivitiesEnabled else {
            presentLiveActivityPermissionDialog(
                .init(
                    openRouteOnly: { openRouteOnly(request) },
                    openSettings: {
                        settingsRequest = request
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        openURL(url)
                    }
                )
            )
            return
        }

        beginTrackingAndOpenRouteGuidance(request)
    }

    private func beginTrackingAndOpenRouteGuidance(_ request: RouteGuidanceRequest) {
        Task {
            let course = RodiCourseItem(placeDetail: request.detail)
            async let routePath = practiceRoutePath(for: course)
            async let profile = try? memberRepository.fetchMyProfile()
            let rabbitAssetName = await profile.map { PracticeLiveActivityRabbitAsset.name(for: $0.level) }
                ?? PracticeLiveActivityRabbitAsset.navigation
            let startResult = PracticeTrackingService.shared.start(
                course: course,
                routePath: await routePath,
                rabbitAssetName: rabbitAssetName
            )

            switch startResult {
            case .started:
                await openRouteGuidance(
                    request.app,
                    detail: request.detail,
                    mode: .gpsTracking,
                    sessionID: PracticeTrackingService.shared.session?.id,
                    cancelTrackingOnFailure: true
                )

            case .authorizationRequested:
                send(.delegate(.showSnackbar("위치 권한을 허용한 뒤 다시 연습하러 가기를 눌러주세요.")))

            case .reducedAccuracyRequested:
                await openRouteGuidance(request.app, detail: request.detail, mode: .routeOnly, sessionID: nil)
                send(.delegate(.showSnackbar("정확한 위치를 허용하면 다음 길안내부터 연습 기록을 시작할 수 있어요.")))

            case .unavailable(let message):
                await openRouteGuidance(request.app, detail: request.detail, mode: .routeOnly, sessionID: nil)
                send(.delegate(.showSnackbar(message)))
            }
        }
    }

    private func practiceRoutePath(for course: RodiCourseItem) async -> [RodiCoordinate] {
        if let roadPath = try? await KakaoDirectionsService().fetchRoute(points: course.routeOverlayPoints), roadPath.count >= 2 {
            return roadPath
        }
        return course.routeOverlayPoints.map(\.coordinate)
    }

    private func openRouteGuidance(
        _ app: RouteGuidanceApp,
        detail: PlaceDetail,
        mode: PracticeMeasurementMode,
        sessionID: UUID?,
        cancelTrackingOnFailure: Bool = false
    ) async {
        let externalHandoffAt = Date.now
        let measurementID = sessionID ?? UUID()
        send(.externalRouteGuidanceWillOpen(
            placeID: detail.id,
            mode: mode,
            measurementID: measurementID,
            externalHandoffAt: externalHandoffAt
        ))
        let result = await RouteGuidanceService.shared.open(
            app,
            for: RodiCourseItem(placeDetail: detail),
            userLocation: userLocation
        )
        if cancelTrackingOnFailure, case .openedApp = result {
            // The tracking session belongs to the successfully opened external guidance flow.
        } else if cancelTrackingOnFailure {
            PracticeTrackingService.shared.cancel()
        }
        if case .openedApp = result {
            // 외부 앱 전환 전에 측정 후보를 저장해, 앱이 바로 suspend되어도 체류 시간을 보존한다.
        } else {
            send(.externalRouteGuidanceFailed(measurementID: measurementID))
        }
        if let message = result.userMessage {
            send(.delegate(.showSnackbar(message)))
        }
    }

    private var areLiveActivitiesEnabled: Bool {
        guard #available(iOS 16.1, *) else { return false }
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }

    private func openRouteOnly(_ request: RouteGuidanceRequest) {
        Task {
            await openRouteGuidance(request.app, detail: request.detail, mode: .routeOnly, sessionID: nil)
        }
    }

    private func openInstallPage(_ app: RouteGuidanceApp) {
        Task {
            let result = await RouteGuidanceService.shared.openInstallPage(for: app)
            if let message = result.userMessage {
                send(.delegate(.showSnackbar(message)))
            }
        }
    }

    private func routeGuidanceDialogConfiguration(
        mode: RouteGuidanceAppDialog.Mode
    ) -> RouteGuidanceAppDialogConfiguration {
        .init(
            mode: mode,
            onceAction: { app in
                guard let detail = state.detail else { return }
                startRouteGuidance(app, detail: detail)
            },
            alwaysAction: { app in
                RouteGuidanceService.shared.savePreferredApp(app)
                guard let detail = state.detail else { return }
                startRouteGuidance(app, detail: detail)
            },
            installAction: openInstallPage
        )
    }
}

struct LiveActivityPermissionDialog: View {
    let routeOnlyAction: () -> Void
    let openSettingsAction: () -> Void
    let closeAction: () -> Void

    var body: some View {
        RodiModalBackground {
            RodiDialog {
                VStack(spacing: 0) {
                    Text("주행 현황 확인을 위해\n실시간 현황을 켜주세요")
                        .rodiTypography(.body1SemiBold)
                        .foregroundStyle(RodiColor.black)
                    Text("앱을 나가도 주행 상태와 연습 진행률을\n확인하려면 주행 상태 알림이 필요해요.")
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 24)
                    HStack(spacing: 8) {
                        ReviewDialogButton(title: "경로만 보기", isPrimary: false) {
                            routeOnlyAction()
                        }
                        ReviewDialogButton(title: "알림 허용하기", isPrimary: true) {
                            openSettingsAction()
                        }
                    }
                    .padding(.top, 24)
                }
            } closeAction: {
                closeAction()
            }
        }
    }
}

//
//  ParkingDetailBottomSheetView.swift
//  Rodi
//

import ActivityKit
import SwiftUI
import UIKit

struct ParkingDetailBottomSheetView: View {
    private struct RouteGuidanceRequest {
        let app: RouteGuidanceApp
        let detail: PlaceDetail
    }

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    let state: ParkingDetailBottomSheetReducer.State
    let send: (ParkingDetailBottomSheetReducer.Action) -> Void
    let userLocation: RodiCoordinate?
    let hasLocationPermission: Bool
    let memberRepository: MemberRepository
    let requestLocationPermission: () -> Void
    let presentActiveMeasurementDialog: (ActiveCourseMeasurementDialogConfiguration) -> Void
    let presentLiveActivityPermissionDialog: (LiveActivityPermissionDialogConfiguration) -> Void
    let presentRouteGuidanceDialog: (RouteGuidanceAppDialogConfiguration) -> Void

    @State private var settingsRequest: RouteGuidanceRequest?

    var body: some View {
        Group {
            if let detail = state.detail {
                ParkingSelectedDetailPanel(
                    detail: detail,
                    isBookmarkUpdating: state.isBookmarkUpdating,
                    isRouteLoading: false,
                    isRouteGuidanceEnabled: true,
                    closeAction: { send(.dismiss) },
                    bookmarkAction: { send(.toggleBookmark) },
                    routeGuidanceAction: requestRouteGuidance
                )
                .frame(maxWidth: .infinity, alignment: .top)
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
            presentActiveMeasurementDialog(.init(
                courseName: PracticeTrackingService.shared.session?.courseName ?? "현재 연습 장소",
                continueAction: {},
                endAction: {
                    PracticeTrackingService.shared.cancel()
                    send(.activeMeasurementEnded)
                    startRouteGuidance(request)
                }
            ))
            return
        }

        guard areLiveActivitiesEnabled else {
            presentLiveActivityPermissionDialog(.init(
                openRouteOnly: { openRouteOnly(request) },
                openSettings: {
                    settingsRequest = request
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(url)
                }
            ))
            return
        }

        beginTrackingAndOpenRouteGuidance(request)
    }

    private func beginTrackingAndOpenRouteGuidance(_ request: RouteGuidanceRequest) {
        Task {
            let parking = RodiCourseItem(placeDetail: request.detail)
            let rabbitAssetName = await (try? memberRepository.fetchMyProfile())
                .map { PracticeLiveActivityRabbitAsset.name(for: $0.level) }
                ?? PracticeLiveActivityRabbitAsset.navigation
            let startResult = PracticeTrackingService.shared.start(
                course: parking,
                routePath: parkingTrackingPath(for: request.detail),
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

    private func openRouteOnly(_ request: RouteGuidanceRequest) {
        Task {
            await openRouteGuidance(request.app, detail: request.detail, mode: .routeOnly, sessionID: nil)
        }
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
            // 측정 세션은 외부 길안내가 열린 경우에만 유지한다.
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

    private func parkingTrackingPath(for detail: PlaceDetail) -> [RodiCoordinate] {
        let center = RodiCoordinate(latitude: detail.latitude, longitude: detail.longitude)
        return [
            center,
            RodiCoordinate(latitude: detail.latitude + 0.00001, longitude: detail.longitude)
        ]
    }

    private var areLiveActivitiesEnabled: Bool {
        guard #available(iOS 16.1, *) else { return false }
        return ActivityAuthorizationInfo().areActivitiesEnabled
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

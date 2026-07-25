//
//  SelectedCoursePanel.swift
//  Rodi
//

import SwiftUI

struct SelectedCoursePanel: View {
    let item: RodiCourseItem
    let detail: PlaceDetail?
    let isDetailLoading: Bool
    let isBookmarkUpdating: Bool
    let isRouteLoading: Bool
    let routeStatusMessage: String?
    let userLocation: RodiCoordinate?
    let hasLocationPermission: Bool
    let closeAction: () -> Void
    let routeGuidanceMessageAction: (String) -> Void
    let routeGuidancePermissionAction: () -> Void
    let bookmarkAction: () -> Void

    @State private var isGuidanceDialogPresented = false
    @State private var isAddressExpanded = false

    private var orderedPoints: [RodiRouteOverlayPoint] {
        item.routeOverlayPoints.sorted { $0.sequence < $1.sequence }
    }

    private var canStartRouteGuidance: Bool {
        return orderedPoints.count >= 2
    }

    private var isSingleLocationRouteGuidance: Bool {
        item.type == .parking
    }

    private var isRouteGuidanceButtonEnabled: Bool {
        if isSingleLocationRouteGuidance {
            return true
        }

        return canStartRouteGuidance
    }

    private var showsRouteGuidanceButton: Bool {
        true
    }

    var body: some View {
        Group {
            if isDetailLoading {
                ProgressView()
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("장소 상세 정보를 불러오는 중")
            } else if let detail, detail.type == .course {
                CourseSelectedDetailPanel(
                    detail: detail,
                    isBookmarkUpdating: isBookmarkUpdating,
                    isRouteLoading: isRouteLoading,
                    isRouteGuidanceEnabled: isRouteGuidanceButtonEnabled,
                    closeAction: closeAction,
                    bookmarkAction: bookmarkAction,
                    routeGuidanceAction: handleRouteGuidanceButtonTap
                )
            } else if let detail, detail.type == .parking {
                ParkingSelectedDetailPanel(
                    detail: detail,
                    isBookmarkUpdating: isBookmarkUpdating,
                    isRouteLoading: isRouteLoading,
                    isRouteGuidanceEnabled: isRouteGuidanceButtonEnabled,
                    closeAction: closeAction,
                    bookmarkAction: bookmarkAction,
                    routeGuidanceAction: handleRouteGuidanceButtonTap
                )
            } else {
                legacyDetailPanel
            }
        }
        .confirmationDialog("경로 안내 앱 선택", isPresented: $isGuidanceDialogPresented, titleVisibility: .visible) {
            Button("카카오맵으로 보기") {
                startRouteGuidance(.kakaoMap)
            }

            Button("카카오내비로 안내") {
                startRouteGuidance(.kakaoNavi)
            }

            Button("취소", role: .cancel) {}
        } message: {
            Text(routeGuidanceDialogMessage)
        }
    }

    private var legacyDetailPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            SelectedCourseHeaderView(title: item.name, closeAction: closeAction)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ExpandableAddressMetaRow(item: item, isExpanded: $isAddressExpanded)

                    if let routeStatusMessage {
                        RouteStatusBannerView(message: routeStatusMessage)
                    }

                    SelectedCourseDetailContent(item: item, orderedPoints: orderedPoints)
                }
                .padding(.horizontal, 16)
                .padding(.top, 0)
                .padding(.bottom, 72)
            }
            .scrollIndicators(.hidden)

            Spacer(minLength: 0)

            if showsRouteGuidanceButton {
                RouteGuidanceButtonBar(
                    isLoading: isRouteLoading,
                    isEnabled: isRouteGuidanceButtonEnabled,
                    action: handleRouteGuidanceButtonTap
                )
            }
        }
    }

    private func startRouteGuidance(_ app: RouteGuidanceApp) {
        guard item.type == .course else {
            Task { await openRouteGuidance(app) }
            return
        }

        Task {
            await startPracticeTrackingAndOpenGuidance(app)
        }
    }

    private func startPracticeTrackingAndOpenGuidance(_ app: RouteGuidanceApp) async {
        let routePath = await practiceRoutePath()
        let startResult = PracticeTrackingService.shared.start(course: item, routePath: routePath)

        switch startResult {
        case .started:
            await openRouteGuidance(app, cancelTrackingOnFailure: true)
        case .authorizationRequested:
            routeGuidanceMessageAction("위치 권한을 허용한 뒤 다시 연습하러 가기를 눌러주세요.")
        case .reducedAccuracyRequested:
            await openRouteGuidance(app)
            routeGuidanceMessageAction("정확한 위치를 허용하면 다음 길안내부터 연습 기록을 시작할 수 있어요.")
        case .unavailable(let message):
            await openRouteGuidance(app)
            routeGuidanceMessageAction(message)
        }
    }

    private func practiceRoutePath() async -> [RodiCoordinate] {
        if let roadPath = try? await KakaoDirectionsService().fetchRoute(points: orderedPoints), roadPath.count >= 2 {
            return roadPath
        }
        return orderedPoints.map(\.coordinate)
    }

    private func openRouteGuidance(_ app: RouteGuidanceApp, cancelTrackingOnFailure: Bool = false) async {
        let result = await RouteGuidanceService.shared.open(app, for: item, userLocation: userLocation)
        if cancelTrackingOnFailure {
            switch result {
            case .openedApp:
                break
            case .openedInstallPage, .failed:
                PracticeTrackingService.shared.cancel()
            }
        }
        if let message = result.userMessage {
            routeGuidanceMessageAction(message)
        }
    }

    private func handleRouteGuidanceButtonTap() {
        guard hasLocationPermission else {
            RodiLogger.info("Route guidance blocked: location permission required itemID=\(item.id), type=\(item.type.rawValue)")
            routeGuidancePermissionAction()
            return
        }

        guard userLocation != nil else {
            RodiLogger.info("Route guidance blocked: waiting for user location itemID=\(item.id), type=\(item.type.rawValue)")
            routeGuidanceMessageAction("현재 위치를 확인한 뒤 다시 시도해주세요.")
            return
        }

        RodiLogger.info("Route guidance chooser presented courseID=\(item.id)")
        isGuidanceDialogPresented = true
    }

    private var routeGuidanceDialogMessage: String {
        isSingleLocationRouteGuidance
            ? "현재 위치에서 선택한 장소까지 안내해요."
            : "출발지, 경유지, 도착지를 함께 전달해요."
    }
}

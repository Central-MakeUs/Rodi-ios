import SwiftUI

struct CourseDetailBottomSheetView: View {
    enum RenderingMode {
        case sheet
        case expanded
    }

    let state: CourseDetailBottomSheetReducer.State
    let send: (CourseDetailBottomSheetReducer.Action) -> Void
    let userLocation: RodiCoordinate?
    let hasLocationPermission: Bool
    let requestLocationPermission: () -> Void
    let titlePanEnabled: Bool
    let titlePanChanged: (CGFloat) -> Void
    let titlePanEnded: (CGFloat) -> Void
    let renderingMode: RenderingMode
    let expandedBackAction: () -> Void

    init(
        state: CourseDetailBottomSheetReducer.State,
        send: @escaping (CourseDetailBottomSheetReducer.Action) -> Void,
        userLocation: RodiCoordinate?,
        hasLocationPermission: Bool,
        requestLocationPermission: @escaping () -> Void,
        titlePanEnabled: Bool = false,
        titlePanChanged: @escaping (CGFloat) -> Void = { _ in },
        titlePanEnded: @escaping (CGFloat) -> Void = { _ in },
        renderingMode: RenderingMode = .sheet,
        expandedBackAction: @escaping () -> Void = {}
    ) {
        self.state = state
        self.send = send
        self.userLocation = userLocation
        self.hasLocationPermission = hasLocationPermission
        self.requestLocationPermission = requestLocationPermission
        self.titlePanEnabled = titlePanEnabled
        self.titlePanChanged = titlePanChanged
        self.titlePanEnded = titlePanEnded
        self.renderingMode = renderingMode
        self.expandedBackAction = expandedBackAction
    }

    var body: some View {
        Group {
            if let detail = state.detail {
                switch renderingMode {
                case .sheet:
                    sheet(detail: detail)
                case .expanded:
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
    }
}

private extension CourseDetailBottomSheetView {
    func sheet(detail: PlaceDetail) -> some View {
        VStack(spacing: 0) {
            CourseSelectedDetailPanel(
                detail: detail,
                isBookmarkUpdating: state.isBookmarkUpdating,
                isRouteLoading: state.isRouteLoading || state.isRouteGuidanceLaunching,
                isRouteGuidanceEnabled: detail.course?.waypoints.count ?? 0 >= 2,
                titlePanEnabled: titlePanEnabled,
                titlePanChanged: titlePanChanged,
                titlePanEnded: titlePanEnded,
                closeAction: { send(.dismiss) },
                bookmarkAction: { send(.toggleBookmark) },
                routeGuidanceAction: requestRouteGuidance
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }

    func requestRouteGuidance() {
        guard hasLocationPermission else {
            requestLocationPermission()
            return
        }
        send(.routeGuidanceTapped(userLocation: userLocation, hasLocationPermission: hasLocationPermission))
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
                        ReviewDialogButton(title: "경로만 보기", isPrimary: false, action: routeOnlyAction)
                        ReviewDialogButton(title: "알림 허용하기", isPrimary: true, action: openSettingsAction)
                    }
                    .padding(.top, 24)
                }
            } closeAction: {
                closeAction()
            }
        }
    }
}

import SwiftUI

struct ParkingDetailBottomSheetView: View {
    let state: ParkingDetailBottomSheetReducer.State
    let send: (ParkingDetailBottomSheetReducer.Action) -> Void
    let userLocation: RodiCoordinate?
    let hasLocationPermission: Bool
    let requestLocationPermission: () -> Void
    let titlePanEnabled: Bool
    let titlePanChanged: (CGFloat) -> Void
    let titlePanEnded: (CGFloat) -> Void

    init(
        state: ParkingDetailBottomSheetReducer.State,
        send: @escaping (ParkingDetailBottomSheetReducer.Action) -> Void,
        userLocation: RodiCoordinate?,
        hasLocationPermission: Bool,
        requestLocationPermission: @escaping () -> Void,
        titlePanEnabled: Bool = false,
        titlePanChanged: @escaping (CGFloat) -> Void = { _ in },
        titlePanEnded: @escaping (CGFloat) -> Void = { _ in }
    ) {
        self.state = state
        self.send = send
        self.userLocation = userLocation
        self.hasLocationPermission = hasLocationPermission
        self.requestLocationPermission = requestLocationPermission
        self.titlePanEnabled = titlePanEnabled
        self.titlePanChanged = titlePanChanged
        self.titlePanEnded = titlePanEnded
    }

    var body: some View {
        Group {
            if let detail = state.detail {
                ParkingSelectedDetailPanel(
                    detail: detail,
                    isBookmarkUpdating: state.isBookmarkUpdating,
                    isRouteLoading: state.isRouteGuidanceLaunching,
                    isRouteGuidanceEnabled: true,
                    titlePanEnabled: titlePanEnabled,
                    titlePanChanged: titlePanChanged,
                    titlePanEnded: titlePanEnded,
                    closeAction: { send(.dismiss) },
                    bookmarkAction: { send(.toggleBookmark) },
                    routeGuidanceAction: requestRouteGuidance
                )
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }

    private func requestRouteGuidance() {
        guard hasLocationPermission else {
            requestLocationPermission()
            return
        }
        send(.routeGuidanceTapped(userLocation: userLocation, hasLocationPermission: hasLocationPermission))
    }
}

import SwiftUI

struct CourseRegistrationMapSelectionView: View {
    let state: CourseRegistrationMapSelectionReducer.State
    let send: (CourseRegistrationMapSelectionReducer.Action) -> Void

    var body: some View {
        ZStack {
            mapView
                .ignoresSafeArea()

            if let target = state.map.selectionTarget ?? state.map.routeFailureTarget {
                CourseRegistrationMovingPin(target: target)
            }

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    CourseRegistrationHeader(
                        title: "코스 등록",
                        closeAction: { send(.closeTapped) }
                    )
                    CourseRegistrationLocationInputs(
                        waypoints: state.waypoints,
                        selectedPlaces: state.selectedPlaces,
                        candidateTarget: state.map.selectionTarget,
                        candidateAddress: state.map.candidateAddress,
                        isSearchEnabled: state.canSearch(for:),
                        isWaypointAdditionEnabled: state.canAddWaypoint,
                        send: send
                    )
                }
                .background(RodiColor.white)

                Spacer()

                HStack {
                    Spacer()
                    CurrentLocationButton(
                        isActive: state.map.isCurrentLocationActive,
                        action: { send(.currentLocationTapped) }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                bottomBar
            }
            .zIndex(1)
        }
        .background(RodiColor.white.ignoresSafeArea())
        .onAppear { send(.appeared) }
        .onDisappear { send(.deactivated) }
    }

    private var mapView: some View {
        KakaoMapContainerView(
            cameraTarget: state.map.cameraTarget,
            cameraRequestID: state.map.cameraRequestID,
            animatedCameraRequestID: nil,
            cameraFocus: .normal,
            userLocation: nil,
            userHeadingDegrees: nil,
            routeOverlay: routeOverlay,
            mapMarkers: [],
            logoBottomInset: 0,
            cameraBottomInset: 0,
            isInteractionEnabled: true,
            visibilityState: .interactive,
            onEvent: { event in
                switch event {
                case let .viewportChanged(center, _, _, isUserInitiated):
                    send(.viewportChanged(center, isUserInitiated: isUserInitiated))
                case let .routePointTap(pointID):
                    send(.routePointTapped(pointID))
                default:
                    break
                }
            }
        )
    }

    @ViewBuilder
    private var bottomBar: some View {
        if let target = state.map.selectionTarget {
            CourseRegistrationSelectionBar(
                targetTitle: target.selectionTitle,
                isSelecting: state.map.isAddressResolving,
                isSelectionEnabled: state.map.candidateCoordinate != nil
                    && state.map.candidateAddress != nil
                    && !state.map.isAddressResolving,
                placeSelectionAction: { send(.placeSelectionTapped) }
            )
        } else {
            CourseRegistrationReadyBar(
                isCompletionEnabled: state.selectedPlaces[.start] != nil && state.selectedPlaces[.destination] != nil,
                isRouteLoading: state.isRouteLoading,
                addWaypointAction: { send(.waypointAddTapped) },
                completionAction: { send(.registrationCompletionTapped) }
            )
        }
    }

    private var routeOverlay: RodiRouteOverlay? {
        let points = state.routePoints()
        guard !points.isEmpty else { return nil }
        return RodiRouteOverlay(
            courseID: 0,
            points: points,
            path: state.routePath,
            isRoadRoute: state.routePath.count >= 2
        )
    }
}

private struct CourseRegistrationSelectionBar: View {
    let targetTitle: String
    let isSelecting: Bool
    let isSelectionEnabled: Bool
    let placeSelectionAction: () -> Void

    var body: some View {
        CourseRegistrationDualButtonBar(
            leadingTitle: isSelecting ? "주소 확인 중..." : targetTitle,
            isLeadingEnabled: isSelectionEnabled,
            leadingAction: placeSelectionAction,
            trailingTitle: "완료",
            isTrailingEnabled: false,
            trailingAction: {}
        )
    }
}

private struct CourseRegistrationReadyBar: View {
    let isCompletionEnabled: Bool
    let isRouteLoading: Bool
    let addWaypointAction: () -> Void
    let completionAction: () -> Void

    var body: some View {
        CourseRegistrationDualButtonBar(
            leadingTitle: "경유지 추가",
            isLeadingEnabled: !isRouteLoading,
            leadingAction: addWaypointAction,
            trailingTitle: isRouteLoading ? "경로 불러오는 중..." : "완료",
            isTrailingEnabled: isCompletionEnabled && !isRouteLoading,
            trailingAction: completionAction
        )
    }
}

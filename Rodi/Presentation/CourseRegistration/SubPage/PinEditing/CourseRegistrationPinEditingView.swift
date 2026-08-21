import SwiftUI

struct CourseRegistrationPinEditingView: View {
    let state: CourseRegistrationPinEditingReducer.State
    let waypoints: [CourseRegistrationWaypoint]
    let selectedPlaces: [CourseRegistrationInputTarget: CourseRegistrationSelectedPlace]
    let send: (CourseRegistrationPinEditingReducer.Action) -> Void

    var body: some View {
        ZStack {
            mapView
                .ignoresSafeArea()

            if state.temporaryPlace == nil {
                CourseRegistrationMovingPin(target: state.target)
            }

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    CourseRegistrationHeader(
                        title: "핀 수정하기",
                        closeAction: { send(.backTapped) }
                    )
                    addressRow
                }
                .background(RodiColor.white)

                Spacer()

                HStack {
                    Spacer()
                    CurrentLocationButton(
                        isActive: state.isCurrentLocationActive,
                        action: { send(.currentLocationTapped) }
                    )
                    .disabled(state.temporaryPlace != nil)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                CourseRegistrationDualButtonBar(
                    leadingTitle: state.temporaryPlace == nil
                        ? (state.isAddressResolving ? "주소 확인 중..." : state.target.selectionTitle)
                        : "다시하기",
                    isLeadingEnabled: state.temporaryPlace != nil || canSelectCandidate,
                    leadingAction: { send(state.temporaryPlace == nil ? .selectionTapped : .retryTapped) },
                    trailingTitle: state.isSaving ? "저장 중..." : "완료",
                    isTrailingEnabled: state.temporaryPlace != nil && !state.isSaving,
                    trailingAction: { send(.completionTapped(overlayPoints)) }
                )
            }
            .zIndex(1)
        }
        .background(RodiColor.white.ignoresSafeArea())
        .onDisappear { send(.deactivated) }
    }

    private var mapView: some View {
        KakaoMapContainerView(
            cameraTarget: state.cameraTarget,
            cameraRequestID: state.cameraRequestID,
            animatedCameraRequestID: nil,
            cameraFocus: .normal,
            userLocation: nil,
            userHeadingDegrees: nil,
            routeOverlay: routeOverlay,
            mapMarkers: [],
            logoBottomInset: 0,
            cameraBottomInset: 0,
            isInteractionEnabled: state.temporaryPlace == nil,
            visibilityState: .interactive,
            onEvent: { event in
                guard case let .viewportChanged(center, _, _, isUserInitiated) = event else {
                    return
                }
                send(.viewportChanged(center, isUserInitiated: isUserInitiated))
            }
        )
    }

    private var addressRow: some View {
        Button(action: { send(.addressTapped) }) {
            HStack(spacing: 8) {
                Image(state.target.inputIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)

                Text(state.temporaryPlace?.name ?? state.candidateAddress ?? state.originalPlace.name)
                    .font(.pretendard(size: 15, weight: .medium))
                    .tracking(-0.3)
                    .foregroundStyle(RodiColor.gray800)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(RodiColor.white)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(RodiColor.gray300, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .accessibilityLabel("\(state.target.selectionTitle) 주소 검색")
    }

    private var canSelectCandidate: Bool {
        state.candidateCoordinate != nil && !state.isAddressResolving
    }

    private var routeOverlay: RodiRouteOverlay? {
        guard !overlayPoints.isEmpty else { return nil }
        return RodiRouteOverlay(courseID: 0, points: overlayPoints, path: [], isRoadRoute: false)
    }

    private var overlayPoints: [RodiRouteOverlayPoint] {
        var points: [RodiRouteOverlayPoint] = []
        for target in orderedTargets {
            guard target != state.target || state.temporaryPlace != nil else { continue }
            let place = target == state.target ? state.temporaryPlace : selectedPlaces[target]
            guard let place else { continue }
            points.append(.init(
                id: points.count,
                sequence: points.count,
                role: target.routePointRole,
                name: place.name,
                coordinate: place.coordinate
            ))
        }
        return points
    }

    private var orderedTargets: [CourseRegistrationInputTarget] {
        var targets: [CourseRegistrationInputTarget] = []
        if selectedPlaces[.start] != nil { targets.append(.start) }
        targets += waypoints.compactMap { waypoint in
            selectedPlaces[.waypoint(waypoint.id)] == nil ? nil : .waypoint(waypoint.id)
        }
        if selectedPlaces[.destination] != nil { targets.append(.destination) }
        return targets
    }
}

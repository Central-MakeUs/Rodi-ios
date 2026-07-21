//
//  HomeView+Actions.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

extension HomeView {
    func handleSheetDragEnded(translation: CGFloat) {
        guard bottomSheetState == .medium else { return }

        let destination = sheetLayout.sheetStateAfterDrag(translation: translation)

        settleBottomSheet(
            from: sheetLayout.height(forDragTranslation: translation),
            to: destination
        )
    }

    /// GestureState가 종료와 동시에 0으로 돌아가기 전에 현재 높이를 붙잡아,
    /// 중간 높이로 튀지 않고 실제 드래그 종료 지점에서 한 번만 스냅한다.
    private func settleBottomSheet(from currentHeight: CGFloat, to destination: HomeBottomSheetState) {
        let settlingID = UUID()
        sheetSettlingID = settlingID
        let duration = destination == .collapsed
            ? Constants.collapsedSheetSnapDuration
            : Constants.defaultSheetSnapDuration

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            settlingSheetHeight = currentHeight
        }

        let targetHeight: CGFloat
        switch destination {
        case .collapsed:
            targetHeight = 0
        case .medium:
            targetHeight = mediumSheetHeight
        case .expanded:
            targetHeight = availableSheetHeight
        }

        DispatchQueue.main.async {
            guard sheetSettlingID == settlingID else { return }

            withAnimation(.easeOut(duration: duration)) {
                settlingSheetHeight = targetHeight
            }
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(duration * 1_000)))
            guard sheetSettlingID == settlingID else { return }

            var completionTransaction = Transaction()
            completionTransaction.disablesAnimations = true
            withTransaction(completionTransaction) {
                switch destination {
                case .collapsed:
                    homeStore.send(.viewAction(.dismissSheet))
                case .medium:
                    homeStore.send(.viewAction(.collapseSheet(mediumHeight: mediumSheetHeight)))
                case .expanded:
                    homeStore.send(.viewAction(.expandSheet(availableHeight: availableSheetHeight)))
                }
                settlingSheetHeight = nil
            }
        }
    }

    func expandBottomSheet() {
        guard bottomSheetState != .expanded else { return }

        withAnimation(.easeOut(duration: 0.25)) {
            homeStore.send(.viewAction(.expandSheet(availableHeight: availableSheetHeight)))
        }
    }

    func collapseBottomSheet() {
        guard bottomSheetState != .collapsed else { return }

        withAnimation(.spring(response: 0.36, dampingFraction: 0.9)) {
            homeStore.send(.viewAction(.collapseSheet(mediumHeight: mediumSheetHeight)))
        }
    }

    func presentBottomSheet() {
        guard bottomSheetState == .collapsed else { return }

        withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
            homeStore.send(.viewAction(.presentSheet(mediumHeight: mediumSheetHeight)))
        }
    }

    func showResearchResultsSheet() {
        switch bottomSheetState {
        case .collapsed:
            presentBottomSheet()
        case .expanded:
            collapseBottomSheet()
        case .medium:
            break
        }
    }

    func dismissBottomSheet() {
        guard bottomSheetState == .medium, !hasFixedBottomSheet else { return }

        withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
            homeStore.send(.viewAction(.dismissSheet))
        }
    }

    func clearSelectedCourse() {
        withAnimation(.easeOut(duration: 0.2)) {
            homeStore.send(.routeAction(.clearSelection))
            homeStore.send(.viewAction(.dismissSheet))
        }
    }

    func handleCourseSelection(_ item: RodiCourseItem) {
        withAnimation(.easeOut(duration: 0.22)) {
            homeStore.send(.routeAction(.selectItem(item, mediumHeight: mediumSheetHeight)))
        }
    }

    func handleMapMarkerTap(_ markerID: String) {
        if runtimeService.focusClusterMarker(markerID: markerID, visibleItems: visibleItems) {
            return
        }

        withAnimation(.easeOut(duration: 0.22)) {
            homeStore.send(.routeAction(.selectMapMarker(markerID: markerID, mediumHeight: mediumSheetHeight)))
        }
    }

    func handlePlaceListSelection(_ item: PlaceListItem) {
        handleCourseSelection(RodiCourseItem(placeListItem: item))
    }

    /// 마이의 저장 목록에서 선택한 장소를 홈의 기존 상세 선택 흐름으로 연결한다.
    func consumePendingPlaceSelectionIfNeeded() {
        guard selectedTab == .home,
              homeStore.state.map.isReady,
              containerHeight > 0,
              let item = pendingPlaceSelection
        else {
            return
        }

        pendingPlaceSelection = nil
        RodiLogger.info(
            "Saved place selection handed off to ready home map placeID=\(item.id), mapHeight=\(containerHeight)"
        )
        handlePlaceListSelection(item)
    }

    func reloadPlaceList() {
        homeStore.send(.placeListAction(.reloadCurrentViewport))
    }

    func loadNextPlaceListPage() {
        homeStore.send(.placeListAction(.loadNextPage))
    }

    func openAppSettings() {
        openSystemAppSettings()
    }

    func openSystemAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }

        UIApplication.shared.open(url, options: [:]) { didOpen in
            RodiLogger.info("Open system app settings requested url=\(url.absoluteString), didOpen=\(didOpen)")
        }
    }

    func showRouteGuidanceMessage(_ message: String) {
        homeStore.send(.presentationAction(.showRouteGuidanceMessage(message)))
    }

    func showLocationSettingsAlert() {
        homeStore.send(.presentationAction(.showLocationSettingsAlert))
    }

    func requestCurrentLocation() {
        RodiLogger.info(
            "Current location floating button tapped selectedItem=\(selectedItem?.id.description ?? "nil"), userLocation=\(userLocationCoordinate.logDescription), cameraTarget=\(RodiLogger.coordinate(cameraTarget)), cameraRequestID=\(cameraRequestID)"
        )
        homeStore.send(.viewAction(.requestCurrentLocation))
        runtimeService.requestCurrentLocationAfterStoreUpdate(
            minimumCameraRequestID: homeStore.state.map.cameraRequestID
        )
    }
}

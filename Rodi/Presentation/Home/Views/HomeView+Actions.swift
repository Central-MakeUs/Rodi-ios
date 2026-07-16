//
//  HomeView+Actions.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

#if canImport(KakaoSDKUser)
import KakaoSDKUser
#endif

extension HomeView {
    func handleSheetDragEnded(predictedTranslation: CGFloat) {
        guard bottomSheetState == .medium else { return }

        if sheetLayout.shouldExpandAfterDrag(predictedTranslation: predictedTranslation) {
            expandBottomSheet()
        } else {
            collapseBottomSheet()
        }
    }

    func expandBottomSheet() {
        guard bottomSheetState != .expanded else { return }

        withAnimation(.easeOut(duration: 0.25)) {
            homeStore.send(.viewAction(.expandSheet(availableHeight: availableSheetHeight)))
        }
    }

    func collapseBottomSheet() {
        guard bottomSheetState != .medium else { return }

        withAnimation(.spring(response: 0.36, dampingFraction: 0.9)) {
            homeStore.send(.viewAction(.collapseSheet(mediumHeight: mediumSheetHeight)))
        }
    }

    func clearSelectedCourse() {
        withAnimation(.easeOut(duration: 0.2)) {
            homeStore.send(.routeAction(.clearSelection))
        }
    }

    func handleCourseSelection(_ item: RodiCourseItem) {
        withAnimation(.easeOut(duration: 0.22)) {
            homeStore.send(.routeAction(.selectItem(item, mediumHeight: mediumSheetHeight)))
        }
    }

    func handleMapMarkerTap(_ markerID: String) {
        withAnimation(.easeOut(duration: 0.22)) {
            homeStore.send(.routeAction(.selectMapMarker(markerID: markerID, mediumHeight: mediumSheetHeight)))
        }
    }

    func handleRadiusFilterSelection(_ filter: HomeRadiusFilter) {
        guard filter != .all else {
            homeStore.send(.viewAction(.applyRadiusFilter(filter)))
            runtimeService.restartProgressiveMarkerRendering(for: homeStore.state.visibleItems)
            return
        }

        guard hasLocationPermission else {
            homeStore.send(.viewAction(.radiusFilterNeedsLocationPermission))
            return
        }

        guard userLocationCoordinate != nil else {
            homeStore.send(.viewAction(.radiusFilterResolvingLocation))
            runtimeService.requestLocation(kind: .userInitiated)
            return
        }

        homeStore.send(.viewAction(.applyRadiusFilter(filter)))
        runtimeService.restartProgressiveMarkerRendering(for: homeStore.state.visibleItems)
    }

    func showAllCourses() {
        homeStore.send(.viewAction(.applyRadiusFilter(.all)))
        runtimeService.restartProgressiveMarkerRendering(for: homeStore.state.visibleItems)
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

    func performLogout() {
        Task {
            do {
                try await authRepository.logout()
                RodiLogger.info("Logout API completed")
            } catch {
                authRepository.clearSession()
                RodiLogger.warning("Logout API failed; local session cleared. error=\(error)")
            }

            await logoutKakaoSDKSessionIfNeeded()

            await MainActor.run {
                homeStore.send(.presentationAction(.setLegalSettingsPresented(false)))
                onLogout()
            }
        }
    }

    func performWithdrawal() {
        Task {
            do {
                try await memberRepository.withdraw()
                RodiLogger.info("Member withdrawal API completed")
            } catch {
                RodiLogger.warning("Member withdrawal API failed. error=\(error)")
                return
            }

            authRepository.clearSession()
            await logoutKakaoSDKSessionIfNeeded()

            await MainActor.run {
                homeStore.send(.presentationAction(.setLegalSettingsPresented(false)))
                onLogout()
            }
        }
    }

    func logoutKakaoSDKSessionIfNeeded() async {
        #if canImport(KakaoSDKUser)
        await withCheckedContinuation { continuation in
            UserApi.shared.logout { error in
                if let error {
                    RodiLogger.warning("Kakao SDK logout failed or no active Kakao session. error=\(error)")
                } else {
                    RodiLogger.info("Kakao SDK logout completed")
                }
                continuation.resume()
            }
        }
        #else
        RodiLogger.debug("Kakao SDK logout skipped: KakaoSDKUser unavailable")
        #endif
    }

    func requestCurrentLocation() {
        RodiLogger.info(
            "Current location floating button tapped selectedItem=\(selectedItem?.id.description ?? "nil"), userLocation=\(userLocationCoordinate.logDescription), cameraTarget=\(RodiLogger.coordinate(cameraTarget)), cameraRequestID=\(cameraRequestID)"
        )
        homeStore.send(.viewAction(.requestCurrentLocation))
        runtimeService.requestCurrentLocationAfterStoreUpdate(
            minimumCameraRequestID: homeStore.state.map.cameraRequestID,
            visibleItems: homeStore.state.visibleItems
        )
    }
}

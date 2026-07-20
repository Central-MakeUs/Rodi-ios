//
//  HomeReducer+View.swift
//  Rodi
//

import Foundation

extension HomeReducer {
    enum HomeEffectID {
        static let routeLoading = "home.route.loading"
        static let guidanceSnackbarDismissal = "home.presentation.guidance-snackbar-dismissal"
        static let locationNoticeDismissal = "home.presentation.location-notice-dismissal"
    }

    func reduceViewAction(_ action: HomeAction.ViewAction, state: inout HomeState) -> Effect<HomeAction> {
        switch action {
        case .setSheetHeight(let height):
            state.bottomSheet.sheetHeight = height

        case .syncMediumSheetHeight(let mediumHeight):
            if state.bottomSheet.bottomSheetState == .medium {
                state.bottomSheet.sheetHeight = mediumHeight
            }

        case .syncExpandedSheetHeight(let containerHeight, let mediumHeight):
            if state.bottomSheet.bottomSheetState == .expanded {
                state.bottomSheet.sheetHeight = max(containerHeight, mediumHeight)
            }

        case .presentSheet(let mediumHeight):
            state.bottomSheet.bottomSheetState = .medium
            state.bottomSheet.sheetHeight = mediumHeight

        case .dismissSheet:
            state.bottomSheet.bottomSheetState = .collapsed
            state.bottomSheet.sheetHeight = 0

        case .expandSheet(let availableHeight):
            guard state.bottomSheet.bottomSheetState != .expanded else { break }
            state.bottomSheet.bottomSheetState = .expanded
            state.bottomSheet.sheetHeight = availableHeight

        case .collapseSheet(let mediumHeight):
            guard state.bottomSheet.bottomSheetState != .medium else { break }
            state.bottomSheet.bottomSheetState = .medium
            state.bottomSheet.sheetHeight = mediumHeight

        case .resetSheetToMedium(let mediumHeight):
            state.bottomSheet.bottomSheetState = .medium
            state.bottomSheet.sheetHeight = mediumHeight

        case .showAllCourses:
            state.data.selectedRadiusFilter = .all

        case .applyRadiusFilter(let filter):
            state.data.selectedRadiusFilter = filter
            state.selection.selectedItem = nil
            state.route.selectedRouteOverlay = nil
            state.map.cameraFocus = .normal
            state.route.routeStatusMessage = nil
            state.route.isRouteLoading = false
            return .cancel(id: HomeEffectID.routeLoading)

        case .radiusFilterNeedsLocationPermission:
            state.presentation.showsLocationSettingsAlert = true

        case .radiusFilterResolvingLocation:
            break

        case .requestCurrentLocation:
            state.selection.selectedItem = nil
            state.route.selectedRouteOverlay = nil
            state.route.routeStatusMessage = nil
            state.route.isRouteLoading = false
            state.map.cameraFocus = .currentLocation
            state.location.isCurrentLocationButtonActive = true
            return .cancel(id: HomeEffectID.routeLoading)
        }

        return .none
    }
}

//
//  HomeView+Lifecycle.swift
//  Rodi
//
//  Created by Codex on 7/4/26.
//

import SwiftUI

extension HomeView {
    func handleContainerHeightChange(_ height: CGFloat) {
        containerHeight = height
        if bottomSheetState == .medium {
            homeStore.send(.viewAction(.syncMediumSheetHeight(mediumSheetHeight)))
        }
        homeStore.send(.viewAction(.syncExpandedSheetHeight(containerHeight: height, mediumHeight: mediumSheetHeight)))
        consumePendingPlaceSelectionIfNeeded()
    }

    func startHomeServices() {
        runtimeService.start(onEvent: handleRuntimeEvent)
        runtimeService.showInitialPlaceMapIfNeeded()
        loadHomeItems()
        networkMonitor.start { isUnavailable in
            homeStore.send(.mapAction(.setNetworkUnavailable(isUnavailable)))
        }
    }

    func stopHomeServices() {
        runtimeService.stop()
        networkMonitor.stop()
    }

    func loadHomeItems() {
        Task {
            do {
                let coordinates = try await placeRepository.fetchCoordinates()
                var items = coordinates.map(RodiCourseItem.init(placeCoordinate:))
                #if DEBUG
                items.append(HomeDebugPlaceFixtures.gasanTestCourse)
                #endif
                homeStore.send(.runtimeAction(.setItems(items)))
                runtimeService.renderInitialMapMarkers(for: homeStore.state.visibleItems)
                RodiLogger.info("Home place coordinates loaded count=\(items.count)")
            } catch {
                #if DEBUG
                let items = [HomeDebugPlaceFixtures.gasanTestCourse]
                homeStore.send(.runtimeAction(.setItems(items)))
                runtimeService.renderInitialMapMarkers(for: items)
                #else
                homeStore.send(.runtimeAction(.setItems([])))
                #endif
                RodiLogger.error("Home place coordinates failed to load error=\(error)")
            }
        }
    }
}

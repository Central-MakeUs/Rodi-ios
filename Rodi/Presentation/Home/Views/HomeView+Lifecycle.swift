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
    }

    func startHomeServices() {
        loadHomeItems()
        runtimeService.start(onEvent: handleRuntimeEvent)
        networkMonitor.start { isUnavailable in
            homeStore.send(.mapAction(.setNetworkUnavailable(isUnavailable)))
        }
    }

    func stopHomeServices() {
        runtimeService.stop()
        networkMonitor.stop()
    }

    func loadHomeItems() {
        do {
            let items = try RodiCourseLoader.loadBundledItems()
            homeStore.send(.runtimeAction(.setItems(items)))
            runtimeService.renderMapMarkers(for: homeStore.state.visibleItems)
            RodiLogger.info("Rodi home items loaded count=\(items.count)")
        } catch {
            homeStore.send(.runtimeAction(.setItems([])))
            RodiLogger.error("Rodi home items failed to load error=\(error)")
        }
    }
}

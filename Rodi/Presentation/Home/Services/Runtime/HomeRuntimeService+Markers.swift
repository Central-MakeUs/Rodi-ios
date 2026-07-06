//
//  HomeRuntimeService+Markers.swift
//  Rodi
//

import SwiftUI

extension HomeRuntimeService {
    func renderMapMarkers(for visibleItems: [RodiCourseItem]) {
        guard isMapViewReady else { return }
        guard !markerRenderingService.isRendering else { return }

        let markers = visibleItems.compactMap(\.mapMarker)
        guard !markers.isEmpty else { return }

        setRenderedMapMarkers([])
        markerRenderingService.renderProgressively(
            markers: markers,
            onUpdate: { [weak self] markers in
                self?.setRenderedMapMarkers(markers)
            },
            onFinish: { [weak self] in
                self?.logStartupTrace("first_marker_render_finished", detail: "count=\(markers.count)")
                RodiLogger.info("Home map markers rendered progressively count=\(markers.count)")
            }
        )
    }

    func restartProgressiveMarkerRendering(for visibleItems: [RodiCourseItem]) {
        markerRenderingService.cancel()
        setRenderedMapMarkers([])
        renderMapMarkers(for: visibleItems)
    }
}

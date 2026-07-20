//
//  HomeRuntimeService+Markers.swift
//  Rodi
//

import SwiftUI

extension HomeRuntimeService {
    /// 최초 데이터 로드에서만 배치 단위로 추가한다. 기존 마커를 비우지 않아 깜빡임을 만들지 않는다.
    func renderInitialMapMarkers(for visibleItems: [RodiCourseItem]) {
        guard isMapViewReady else { return }

        let tier = RodiHomeMarkerClusterIndex.Tier(zoomLevel: mapViewport.zoomLevel)
        let markers = markerSnapshot(for: visibleItems, tier: tier)
        guard !markers.isEmpty else {
            applyMarkerSnapshot([], tier: tier)
            return
        }
        guard lastRequestedMarkerSnapshot.isEmpty else {
            refreshMapMarkers(for: visibleItems)
            return
        }
        guard !markerRenderingService.isRendering else { return }

        lastAppliedMarkerTier = tier
        lastRequestedMarkerSnapshot = markers
        markerRenderingService.renderProgressively(
            markers: markers,
            onUpdate: { [weak self] markers in
                self?.setRenderedMapMarkers(markers)
            },
            onFinish: { [weak self] in
                self?.logStartupTrace("first_marker_render_finished", detail: "count=\(markers.count), zoom=\(self?.mapViewport.zoomLevel ?? 0)")
                RodiLogger.info("Home map markers rendered progressively count=\(markers.count), zoom=\(self?.mapViewport.zoomLevel ?? 0)")
            }
        )
    }

    /// 데이터 또는 필터가 바뀐 경우에만 전체 snapshot을 갱신한다.
    /// 같은 ID의 POI는 지도 adapter가 유지하므로 전체 삭제가 일어나지 않는다.
    func refreshMapMarkers(for visibleItems: [RodiCourseItem]) {
        guard isMapViewReady else { return }

        let tier = displayTier(for: mapViewport.zoomLevel)
        applyMarkerSnapshot(markerSnapshot(for: visibleItems, tier: tier), tier: tier)
    }

    /// 카메라가 멈춘 뒤 Tier가 달라진 경우에만 cluster 병합·분리를 적용한다.
    func updateMapMarkersForViewportIfNeeded(for visibleItems: [RodiCourseItem]) {
        let tier = displayTier(for: mapViewport.zoomLevel)
        guard tier != lastAppliedMarkerTier else {
            RodiLogger.debug("Home marker refresh skipped: unchanged tier=\(tier.id)")
            return
        }

        refreshMapMarkers(for: visibleItems)
    }

    func focusClusterMarker(
        markerID: String,
        visibleItems: [RodiCourseItem]
    ) -> Bool {
        guard let target = RodiHomeMarkerClusterIndex.focusTarget(
            for: markerID,
            items: visibleItems
        ) else {
            return false
        }

        forcedMarkerTier = target.nextTier
        forcedMarkerZoomLevel = nil
        let center = averagedCoordinate(of: target.coordinates)
        let requestID = nextCameraRequest()
        emitCameraState(
            target: center,
            requestID: requestID,
            animatedRequestID: requestID,
            focus: .cluster(target.coordinates)
        )
        RodiLogger.info(
            "Home cluster focus requested markerID=\(markerID), nextTier=\(target.nextTier.id), pointCount=\(target.coordinates.count)"
        )
        return true
    }

    private func displayTier(for zoomLevel: Int) -> RodiHomeMarkerClusterIndex.Tier {
        let naturalTier = RodiHomeMarkerClusterIndex.Tier(zoomLevel: zoomLevel)
        guard let forcedMarkerTier else { return naturalTier }

        if let forcedMarkerZoomLevel, forcedMarkerZoomLevel != zoomLevel {
            self.forcedMarkerTier = nil
            self.forcedMarkerZoomLevel = nil
            return naturalTier
        }

        forcedMarkerZoomLevel = zoomLevel
        return forcedMarkerTier
    }

    private func markerSnapshot(
        for visibleItems: [RodiCourseItem],
        tier: RodiHomeMarkerClusterIndex.Tier
    ) -> [RodiMapMarker] {
        RodiHomeMarkerClusterIndex.markers(for: visibleItems, tier: tier)
    }

    private func averagedCoordinate(of coordinates: [RodiCoordinate]) -> RodiCoordinate {
        let latitude = coordinates.map(\.latitude).reduce(0, +) / Double(coordinates.count)
        let longitude = coordinates.map(\.longitude).reduce(0, +) / Double(coordinates.count)
        return RodiCoordinate(latitude: latitude, longitude: longitude)
    }

    private func applyMarkerSnapshot(
        _ markers: [RodiMapMarker],
        tier: RodiHomeMarkerClusterIndex.Tier
    ) {
        guard lastRequestedMarkerSnapshot != markers else { return }

        markerRenderingService.cancel()
        lastAppliedMarkerTier = tier
        lastRequestedMarkerSnapshot = markers
        setRenderedMapMarkers(markers)

        RodiLogger.info("Home marker snapshot applied tier=\(tier.id), count=\(markers.count)")
    }
}

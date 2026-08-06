//
//  RodiHomeMarkerClusterIndex.swift
//  Rodi
//

import Foundation

/// 서버에서 한 번 받은 전체 좌표 목록을 주소 단위로 안정적으로 묶는다.
/// 화면 이동은 같은 주소 묶음을 재계산하지 않고, 카메라 정지 시 줌 단계만 바꾼다.
struct RodiHomeMarkerClusterIndex {
    struct ClusterFocusTarget {
        let nextTier: Tier
        let coordinates: [RodiCoordinate]
    }

    enum Tier: Equatable {
        case province
        case district
        case individual

        init(zoomLevel: Int) {
            switch zoomLevel {
            case ...8:
                self = .province
            case 9...11:
                self = .district
            default:
                self = .individual
            }
        }

        var id: String {
            switch self {
            case .province: "province"
            case .district: "district"
            case .individual: "individual"
            }
        }

        var addressComponentCount: Int {
            switch self {
            case .province: 1
            case .district: 2
            case .individual: 0
            }
        }

        var nextTier: Tier? {
            switch self {
            case .province:
                .district
            case .district:
                .individual
            case .individual:
                nil
            }
        }

    }

    static func markers(
        for items: [RodiCourseItem],
        zoomLevel: Int,
        selectedMarkerID: String? = nil
    ) -> [RodiMapMarker] {
        let tier = Tier(zoomLevel: zoomLevel)
        return markers(
            for: items,
            tier: tier,
            selectedMarkerID: selectedMarkerID
        )
    }

    static func markers(
        for items: [RodiCourseItem],
        tier: Tier,
        selectedMarkerID: String? = nil
    ) -> [RodiMapMarker] {
        let markers: [RodiMapMarker]

        if tier == .individual {
            markers = items.compactMap(\.mapMarker)
        } else {
            let groups = Dictionary(grouping: items) {
                regionalKey(for: $0.address, componentCount: tier.addressComponentCount)
            }

            markers = groups
                .compactMap { key, members -> RodiMapMarker? in
                    guard !members.isEmpty else { return nil }
                    let coordinate = averagedCoordinate(of: members)
                    return RodiMapMarker(
                        id: "cluster:\(tier.id):\(key)",
                        kind: .cluster,
                        title: String(members.count),
                        coordinate: coordinate
                    )
                }
                .sorted { $0.id < $1.id }
        }

        return markers.map { marker in
            RodiMapMarker(
                id: marker.id,
                kind: marker.kind,
                title: marker.title,
                coordinate: marker.coordinate,
                isSelected: marker.id == selectedMarkerID
            )
        }
    }

    /// 선택된 cluster의 다음 표시 단계가 모두 들어오도록 필요한 좌표를 반환한다.
    static func focusTarget(
        for clusterMarkerID: String,
        items: [RodiCourseItem]
    ) -> ClusterFocusTarget? {
        guard let (tier, clusterKey) = clusterIdentity(from: clusterMarkerID),
              let nextTier = tier.nextTier
        else {
            return nil
        }

        let members = items.filter {
            regionalKey(for: $0.address, componentCount: tier.addressComponentCount) == clusterKey
        }
        let nextMarkers = markers(for: members, tier: nextTier)
        guard !nextMarkers.isEmpty else { return nil }

        return ClusterFocusTarget(
            nextTier: nextTier,
            coordinates: nextMarkers.map { $0.coordinate }
        )
    }

    private static func clusterIdentity(from markerID: String) -> (Tier, String)? {
        for tier in [Tier.province, .district] {
            let prefix = "cluster:\(tier.id):"
            guard markerID.hasPrefix(prefix) else { continue }

            let key = String(markerID.dropFirst(prefix.count))
            guard !key.isEmpty else { return nil }
            return (tier, key)
        }
        return nil
    }

    private static func regionalKey(for address: String, componentCount: Int) -> String {
        let components = address
            .split(whereSeparator: \.isWhitespace)
            .prefix(componentCount)

        let key = components.joined(separator: " ")
        return key.isEmpty ? "unknown" : key
    }

    private static func averagedCoordinate(of items: [RodiCourseItem]) -> RodiCoordinate {
        let latitude = items.map(\.lat).reduce(0, +) / Double(items.count)
        let longitude = items.map(\.lng).reduce(0, +) / Double(items.count)
        return RodiCoordinate(latitude: latitude, longitude: longitude)
    }
}

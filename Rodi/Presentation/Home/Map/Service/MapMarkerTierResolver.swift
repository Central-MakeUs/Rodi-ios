//
//  MapMarkerTierResolver.swift
//  Rodi
//

import Foundation

struct MapMarkerTierResolver {
    struct Resolution {
        let tier: RodiHomeMarkerClusterIndex.Tier
        let forcedTier: RodiHomeMarkerClusterIndex.Tier?
        let forcedTierZoomLevel: Int?
    }

    func resolve(
        zoomLevel: Int,
        forcedTier: RodiHomeMarkerClusterIndex.Tier?,
        forcedTierZoomLevel: Int?
    ) -> Resolution {
        let naturalTier = RodiHomeMarkerClusterIndex.Tier(zoomLevel: zoomLevel)

        guard let forcedTier else {
            return Resolution(
                tier: naturalTier,
                forcedTier: nil,
                forcedTierZoomLevel: forcedTierZoomLevel
            )
        }

        if let forcedTierZoomLevel,
           forcedTierZoomLevel != zoomLevel {
            return Resolution(
                tier: naturalTier,
                forcedTier: nil,
                forcedTierZoomLevel: nil
            )
        }

        return Resolution(
            tier: forcedTier,
            forcedTier: forcedTier,
            forcedTierZoomLevel: zoomLevel
        )
    }
}

//
//  HomeViewState.swift
//  Rodi
//

import Foundation

enum HomeOverlayState: Equatable {
    case loading
    case networkUnavailable
    case mapUnavailable(message: String)
}

struct RodiMapViewport: Equatable {
    let center: RodiCoordinate
    let zoomLevel: Int

    static let initial = RodiMapViewport(
        center: .seoulCityHall,
        zoomLevel: 14
    )
}

enum HomeBottomSheetState: Equatable {
    case collapsed
    case medium
    case expanded
}

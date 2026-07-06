//
//  HomeViewState.swift
//  Rodi
//

import Foundation

enum HomeOverlayState: Equatable {
    case loading(HomeLoadingKind)
    case networkUnavailable
    case mapUnavailable(message: String)
}

enum HomeLoadingKind: Equatable {
    case map
}


struct RodiMapViewport: Equatable {
    let center: RodiCoordinate
    let zoomLevel: Int

    static let initial = RodiMapViewport(center: .seoulCityHall, zoomLevel: 14)
}

enum HomeBottomSheetState {
    case medium
    case expanded
}

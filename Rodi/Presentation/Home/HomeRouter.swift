//
//  HomeRouter.swift
//  Rodi
//

import Combine
import Foundation

enum HomeRoute: Identifiable {
    case search(origin: RodiCoordinate)

    var id: String {
        switch self {
        case .search:
            "search"
        }
    }
}

struct HomeAdministrativeAreaDestination: Equatable {
    let name: String
    let coordinate: RodiCoordinate
    let bounds: RodiMapBounds
}

@MainActor
final class HomeRouter: ObservableObject {
    @Published private(set) var pendingPlaceID: Int?
    @Published private(set) var pendingAdministrativeArea: HomeAdministrativeAreaDestination?
    @Published private(set) var selectedSearchResultName: String?
    @Published private(set) var bottomSheetState: HomeBottomSheetState = .collapsed
    @Published private(set) var listPresentationRequestID = 0
    @Published private(set) var presentedRoute: HomeRoute?

    func presentSearch(origin: RodiCoordinate) {
        presentedRoute = .search(origin: origin)
    }

    func dismissPresentedRoute() {
        presentedRoute = nil
    }

    func completeSearch(place: PlaceListItem) {
        presentedRoute = nil
        selectedSearchResultName = place.name
        DispatchQueue.main.async { [weak self] in
            self?.showPlace(id: place.id)
        }
    }

    func completeSearch(administrativeArea: KoreanAdministrativeArea) {
        presentedRoute = nil
        let destination = HomeAdministrativeAreaDestination(
            name: administrativeArea.searchDisplayName,
            coordinate: administrativeArea.coordinate,
            bounds: administrativeArea.bounds
        )
        selectedSearchResultName = destination.name
        DispatchQueue.main.async { [weak self] in
            self?.showAdministrativeArea(destination)
        }
    }

    func showPlace(id: Int) {
        pendingPlaceID = id
    }

    func consumePendingPlaceID() -> Int? {
        defer { pendingPlaceID = nil }
        return pendingPlaceID
    }

    func showAdministrativeArea(_ destination: HomeAdministrativeAreaDestination) {
        pendingAdministrativeArea = destination
    }

    func consumePendingAdministrativeArea() -> HomeAdministrativeAreaDestination? {
        defer { pendingAdministrativeArea = nil }
        return pendingAdministrativeArea
    }

    func clearSelectedSearchResult() {
        selectedSearchResultName = nil
    }

    func updateBottomSheetState(_ state: HomeBottomSheetState) {
        bottomSheetState = state
    }

    func requestListPresentation() {
        listPresentationRequestID += 1
    }

    func reset() {
        pendingPlaceID = nil
        pendingAdministrativeArea = nil
        selectedSearchResultName = nil
        bottomSheetState = .collapsed
        listPresentationRequestID = 0
        presentedRoute = nil
    }
}

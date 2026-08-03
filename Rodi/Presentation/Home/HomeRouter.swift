//
//  HomeRouter.swift
//  Rodi
//

import Combine
import Foundation

enum HomePresentation: Identifiable {
    case search(origin: RodiCoordinate)

    var id: String {
        switch self {
        case .search:
            "search"
        }
    }
}

struct HomeAdministrativeAreaSearchDestination: Equatable {
    let name: String
    let coordinate: RodiCoordinate
    let bounds: RodiMapBounds
    let items: [PlaceListItem]
}

@MainActor
final class HomeRouter: ObservableObject {
    @Published private(set) var pendingPlaceID: Int?
    @Published private(set) var pendingAdministrativeAreaSearch: HomeAdministrativeAreaSearchDestination?
    @Published private(set) var activeAdministrativeAreaSearch: HomeAdministrativeAreaSearchDestination?
    @Published private(set) var selectedSearchResultName: String?
    @Published private(set) var listPresentationRequestID = 0
    @Published private(set) var presentedPresentation: HomePresentation?

    func presentSearch(origin: RodiCoordinate) {
        presentedPresentation = .search(origin: origin)
    }

    func dismissPresentation() {
        presentedPresentation = nil
    }

    func completeSearch(place: PlaceListItem) {
        presentedPresentation = nil
        clearAdministrativeAreaSearch()
        selectedSearchResultName = place.name
        DispatchQueue.main.async { [weak self] in
            self?.showPlace(id: place.id)
        }
    }

    func completeSearch(administrativeAreaSearch result: AdministrativeAreaSearchResult) {
        presentedPresentation = nil
        let destination = HomeAdministrativeAreaSearchDestination(
            name: result.area.searchDisplayName,
            coordinate: result.area.coordinate,
            bounds: result.area.bounds,
            items: result.items
        )
        selectedSearchResultName = destination.name
        DispatchQueue.main.async { [weak self] in
            self?.showAdministrativeAreaSearch(destination)
        }
    }

    func showPlace(id: Int) {
        pendingPlaceID = id
    }

    func consumePendingPlaceID() -> Int? {
        defer { pendingPlaceID = nil }
        return pendingPlaceID
    }

    func showAdministrativeAreaSearch(_ destination: HomeAdministrativeAreaSearchDestination) {
        activeAdministrativeAreaSearch = destination
        pendingAdministrativeAreaSearch = destination
    }

    func consumePendingAdministrativeAreaSearch() -> HomeAdministrativeAreaSearchDestination? {
        defer { pendingAdministrativeAreaSearch = nil }
        return pendingAdministrativeAreaSearch
    }

    func clearSelectedSearchResult() {
        selectedSearchResultName = nil
    }

    func clearSelectedPlaceSearchResult() {
        guard activeAdministrativeAreaSearch == nil else { return }
        selectedSearchResultName = nil
    }

    func clearAdministrativeAreaSearch() {
        pendingAdministrativeAreaSearch = nil
        activeAdministrativeAreaSearch = nil
        selectedSearchResultName = nil
    }

    func requestListPresentation() {
        listPresentationRequestID += 1
    }

    func reset() {
        pendingPlaceID = nil
        pendingAdministrativeAreaSearch = nil
        activeAdministrativeAreaSearch = nil
        selectedSearchResultName = nil
        listPresentationRequestID = 0
        presentedPresentation = nil
    }
}

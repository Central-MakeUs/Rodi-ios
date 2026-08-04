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

@MainActor
final class HomeRouter: ObservableObject {
    @Published private(set) var pendingPlaceID: Int?
    @Published private(set) var selectedSearchResultName: String?
    @Published private(set) var listPresentationRequestID = 0
    @Published private(set) var presentedPresentation: HomePresentation?

    func presentSearch(origin: RodiCoordinate) {
        presentedPresentation = .search(origin: origin)
    }

    func dismissPresentation() {
        presentedPresentation = nil
    }

    func completeSearch(placeID: Int, name: String) {
        presentedPresentation = nil
        selectedSearchResultName = name
        DispatchQueue.main.async { [weak self] in
            self?.showPlace(id: placeID)
        }
    }

    func showPlace(id: Int) {
        pendingPlaceID = id
    }

    func consumePendingPlaceID() -> Int? {
        defer { pendingPlaceID = nil }
        return pendingPlaceID
    }

    func clearSelectedSearchResult() {
        selectedSearchResultName = nil
    }

    func clearSelectedPlaceSearchResult() {
        selectedSearchResultName = nil
    }

    func requestListPresentation() {
        listPresentationRequestID += 1
    }

    func reset() {
        pendingPlaceID = nil
        selectedSearchResultName = nil
        listPresentationRequestID = 0
        presentedPresentation = nil
    }
}

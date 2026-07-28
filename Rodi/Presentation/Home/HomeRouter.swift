//
//  HomeRouter.swift
//  Rodi
//

import Combine
import Foundation

@MainActor
final class HomeRouter: ObservableObject {
    @Published private(set) var pendingPlaceID: Int?
    @Published private(set) var bottomSheetState: HomeBottomSheetState = .collapsed
    @Published private(set) var listPresentationRequestID = 0

    func showPlace(id: Int) {
        pendingPlaceID = id
    }

    func consumePendingPlaceID() -> Int? {
        defer { pendingPlaceID = nil }
        return pendingPlaceID
    }

    func updateBottomSheetState(_ state: HomeBottomSheetState) {
        bottomSheetState = state
    }

    func requestListPresentation() {
        listPresentationRequestID += 1
    }

    func reset() {
        pendingPlaceID = nil
        bottomSheetState = .collapsed
        listPresentationRequestID = 0
    }
}

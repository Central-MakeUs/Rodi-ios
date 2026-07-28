//
//  OnboardingLocationPermissionReducer.swift
//  Rodi
//

import Foundation

struct OnboardingLocationPermissionReducer: Reducer {
    struct State {
        init() {}
    }

    enum Action {
        case continueTapped
    }

    private let requester: LocationPermissionRequester

    init(requester: LocationPermissionRequester = .shared) {
        self.requester = requester
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .continueTapped:
            requester.requestPermission()
        }

        return .none
    }
}

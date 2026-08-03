//
//  OnboardingPermissionReducer.swift
//  Rodi
//

import Foundation

struct OnboardingPermissionReducer: Reducer {
    struct State {
        enum Screen { case safety, locationPermission }

        var screen: Screen
        var session: OnboardingSession
        var agreedSafetyItems: Set<SafetyAgreement>
        var transition: OnboardingTransition?

        init(session: OnboardingSession, screen: Screen) {
            self.screen = screen
            self.session = session
            agreedSafetyItems = session.agreedSafetyItems
        }

        var isAllSafetyAgreed: Bool { agreedSafetyItems.count == SafetyAgreement.allCases.count }
    }

    enum Action {
        case toggleSafety(SafetyAgreement)
        case safetyNextTapped
        case locationContinueTapped
        case backTapped
        case transitionConsumed
    }

    private let requester: LocationPermissionRequester

    init(requester: LocationPermissionRequester = .shared) {
        self.requester = requester
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .toggleSafety(let item):
            if state.agreedSafetyItems.contains(item) {
                state.agreedSafetyItems.remove(item)
            } else {
                state.agreedSafetyItems.insert(item)
            }

        case .safetyNextTapped:
            guard state.isAllSafetyAgreed else { return .none }
            state.session.agreedSafetyItems = state.agreedSafetyItems
            RodiAnalytics.track(.onboardingStepCompleted(step: "safety", entryMode: state.session.entryMode))
            state.transition = .init(updatedSession: state.session, navigation: .push(.locationPermission))

        case .locationContinueTapped:
            requester.requestPermission()
            RodiAnalytics.track(.onboardingStepCompleted(step: "location_permission", entryMode: state.session.entryMode))
            RodiAnalytics.track(.onboardingCompleted(entryMode: state.session.entryMode, memberLevel: "unknown"))
            state.transition = .init(updatedSession: state.session, navigation: .complete)

        case .backTapped:
            state.transition = .init(updatedSession: state.session, navigation: .pop)

        case .transitionConsumed:
            state.transition = nil
        }
        return .none
    }
}

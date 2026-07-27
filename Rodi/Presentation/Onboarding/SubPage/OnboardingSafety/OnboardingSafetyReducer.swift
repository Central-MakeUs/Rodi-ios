//
//  OnboardingSafetyReducer.swift
//  Rodi
//

import Foundation

struct OnboardingSafetyReducer: Reducer {
    struct State {
        var agreedSafetyItems: Set<SafetyAgreement>

        init(agreedSafetyItems: Set<SafetyAgreement> = []) {
            self.agreedSafetyItems = agreedSafetyItems
        }

        var isAllSafetyAgreed: Bool {
            agreedSafetyItems.count == SafetyAgreement.allCases.count
        }
    }

    enum Action {
        case toggle(SafetyAgreement)
        case nextTapped
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .toggle(let item):
            if state.agreedSafetyItems.contains(item) {
                state.agreedSafetyItems.remove(item)
            } else {
                state.agreedSafetyItems.insert(item)
            }

        case .nextTapped:
            guard state.isAllSafetyAgreed else { return .none }
        }

        return .none
    }
}

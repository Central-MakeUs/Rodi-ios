//
//  OnboardingTermsReducer.swift
//  Rodi
//

import Foundation

struct OnboardingTermsReducer: Reducer {
    struct State {
        var agreedTerms: Set<TermsAgreement>
        var selectedTermsPage: TermsAgreement?

        init(agreedTerms: Set<TermsAgreement> = []) {
            self.agreedTerms = agreedTerms
        }

        var isAllTermsAgreed: Bool {
            agreedTerms.count == TermsAgreement.allCases.count
        }
    }

    enum Action {
        case toggleAll
        case toggle(TermsAgreement)
        case open(TermsAgreement)
        case dismissTermsPage
        case nextTapped
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .toggleAll:
            state.agreedTerms = state.isAllTermsAgreed
                ? []
                : Set(TermsAgreement.allCases)

        case .toggle(let terms):
            if state.agreedTerms.contains(terms) {
                state.agreedTerms.remove(terms)
            } else {
                state.agreedTerms.insert(terms)
            }

        case .open(let terms):
            state.selectedTermsPage = terms

        case .dismissTermsPage:
            state.selectedTermsPage = nil

        case .nextTapped:
            guard state.isAllTermsAgreed else { return .none }
        }

        return .none
    }
}

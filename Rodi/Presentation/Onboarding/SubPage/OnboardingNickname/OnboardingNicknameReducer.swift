//
//  OnboardingNicknameReducer.swift
//  Rodi
//

import Foundation

struct OnboardingNicknameReducer: Reducer {
    struct State {
        var nickname: String

        init(nickname: String = "") {
            self.nickname = nickname
        }

        var canProceed: Bool {
            !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    enum Action {
        case nicknameChanged(String)
        case nextTapped
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .nicknameChanged(let nickname):
            state.nickname = nickname

        case .nextTapped:
            guard state.canProceed else { return .none }
        }

        return .none
    }
}

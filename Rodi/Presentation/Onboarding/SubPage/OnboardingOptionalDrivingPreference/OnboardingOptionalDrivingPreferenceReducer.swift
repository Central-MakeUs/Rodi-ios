//
//  OnboardingOptionalDrivingPreferenceReducer.swift
//  Rodi
//

import Foundation

struct OnboardingOptionalDrivingPreferenceReducer: Reducer {
    struct Preferences: Equatable {
        var selectedPracticeSituations: [PracticeSituation]
        var vehicleType: VehicleType?

        init(
            selectedPracticeSituations: [PracticeSituation] = [],
            vehicleType: VehicleType? = nil
        ) {
            self.selectedPracticeSituations = selectedPracticeSituations
            self.vehicleType = vehicleType
        }

        var canProceed: Bool {
            !selectedPracticeSituations.isEmpty && vehicleType != nil
        }
    }

    struct State {
        var preferences: Preferences

        init(preferences: Preferences = Preferences()) {
            self.preferences = preferences
        }
    }

    enum Action {
        case togglePracticeSituation(PracticeSituation)
        case selectVehicleType(VehicleType)
        case skipTapped
        case nextTapped(drivingGoal: String)
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .togglePracticeSituation(let situation):
            if let index = state.preferences.selectedPracticeSituations.firstIndex(of: situation) {
                state.preferences.selectedPracticeSituations.remove(at: index)
            } else if state.preferences.selectedPracticeSituations.count < 3 {
                state.preferences.selectedPracticeSituations.append(situation)
            }

        case .selectVehicleType(let vehicleType):
            state.preferences.vehicleType = vehicleType

        case .skipTapped:
            break

        case .nextTapped:
            guard state.preferences.canProceed else { return .none }
        }

        return .none
    }
}

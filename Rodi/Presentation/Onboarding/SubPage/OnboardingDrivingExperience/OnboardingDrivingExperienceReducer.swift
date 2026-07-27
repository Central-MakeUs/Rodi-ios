//
//  OnboardingDrivingExperienceReducer.swift
//  Rodi
//

import Foundation

struct OnboardingDrivingExperienceReducer: Reducer {
    struct Answers: Equatable {
        var licenseDrivingPeriod: LicenseDrivingPeriod?
        var recentDrivingFrequency: RecentDrivingFrequency?
        var selectedRoadDrivingExperiences: [RoadDrivingExperience]
        var soloDrivingRange: SoloDrivingRange?
        var soloParkingLevel: SoloParkingLevel?

        init(
            licenseDrivingPeriod: LicenseDrivingPeriod? = nil,
            recentDrivingFrequency: RecentDrivingFrequency? = nil,
            selectedRoadDrivingExperiences: [RoadDrivingExperience] = [],
            soloDrivingRange: SoloDrivingRange? = nil,
            soloParkingLevel: SoloParkingLevel? = nil
        ) {
            self.licenseDrivingPeriod = licenseDrivingPeriod
            self.recentDrivingFrequency = recentDrivingFrequency
            self.selectedRoadDrivingExperiences = selectedRoadDrivingExperiences
            self.soloDrivingRange = soloDrivingRange
            self.soloParkingLevel = soloParkingLevel
        }

        var canProceed: Bool {
            guard licenseDrivingPeriod != nil,
                  recentDrivingFrequency != nil,
                  !selectedRoadDrivingExperiences.isEmpty
            else {
                return false
            }

            guard selectedRoadDrivingExperiences.contains(.soloPractice) else {
                return true
            }

            return soloDrivingRange != nil && soloParkingLevel != nil
        }
    }

    struct State {
        var answers: Answers

        init(answers: Answers = Answers()) {
            self.answers = answers
        }
    }

    enum Action {
        case selectLicenseDrivingPeriod(LicenseDrivingPeriod)
        case selectRecentDrivingFrequency(RecentDrivingFrequency)
        case toggleRoadDrivingExperience(RoadDrivingExperience)
        case selectSoloDrivingRange(SoloDrivingRange)
        case selectSoloParkingLevel(SoloParkingLevel)
        case nextTapped
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .selectLicenseDrivingPeriod(let period):
            state.answers.licenseDrivingPeriod = period

        case .selectRecentDrivingFrequency(let frequency):
            state.answers.recentDrivingFrequency = frequency

        case .toggleRoadDrivingExperience(let experience):
            toggleRoadDrivingExperience(experience, answers: &state.answers)

        case .selectSoloDrivingRange(let range):
            state.answers.soloDrivingRange = range

        case .selectSoloParkingLevel(let level):
            state.answers.soloParkingLevel = level

        case .nextTapped:
            guard state.answers.canProceed else { return .none }
        }

        return .none
    }

    private func toggleRoadDrivingExperience(
        _ experience: RoadDrivingExperience,
        answers: inout Answers
    ) {
        if experience == .none {
            answers.selectedRoadDrivingExperiences = answers.selectedRoadDrivingExperiences == [.none]
                ? []
                : [.none]
        } else if let index = answers.selectedRoadDrivingExperiences.firstIndex(of: experience) {
            answers.selectedRoadDrivingExperiences.remove(at: index)
        } else {
            answers.selectedRoadDrivingExperiences.removeAll { $0 == .none }
            answers.selectedRoadDrivingExperiences.append(experience)
        }

        if !answers.selectedRoadDrivingExperiences.contains(.soloPractice) {
            answers.soloDrivingRange = nil
            answers.soloParkingLevel = nil
        }
    }
}

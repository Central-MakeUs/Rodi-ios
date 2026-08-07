//
//  OnboardingProfileAnswers.swift
//  Rodi
//

import Foundation

struct OnboardingDrivingExperience: Equatable {
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
              !selectedRoadDrivingExperiences.isEmpty else {
            return false
        }

        return !selectedRoadDrivingExperiences.contains(.soloPractice)
            || (soloDrivingRange != nil && soloParkingLevel != nil)
    }
}

struct OnboardingDrivingPreferences: Equatable {
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

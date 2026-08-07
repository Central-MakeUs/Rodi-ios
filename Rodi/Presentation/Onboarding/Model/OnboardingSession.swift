//
//  OnboardingSession.swift
//  Rodi
//

import Foundation

struct OnboardingSession: Equatable {
    enum Mode: Equatable {
        case guest
        case member(SocialLoginProvider)
    }

    var mode: Mode?
    var agreedTerms: Set<TermsAgreement>
    var nickname: String?
    var drivingExperience: OnboardingDrivingExperience?
    var preferences: OnboardingDrivingPreferences?
    var drivingGoal: String?
    var agreedSafetyItems: Set<SafetyAgreement>
    var requiresDrivingExperienceReselection: Bool

    init(payload: OnboardingDraftPayload? = nil) {
        let drivingPeriod = payload?.licenseDrivingPeriodRawValue.flatMap(LicenseDrivingPeriod.init(rawValue:))
        let roadExperienceRawValues = payload?.roadDrivingExperienceRawValues
            ?? payload?.roadDrivingExperienceRawValue.map { [$0] }
            ?? []

        mode = payload.flatMap { SocialLoginProvider(rawValue: $0.providerRawValue) }.map(Mode.member)
        agreedTerms = Set(payload?.agreedTermsRawValues.compactMap(TermsAgreement.init(rawValue:)) ?? [])
        nickname = payload?.nickname
        drivingExperience = .init(
            licenseDrivingPeriod: drivingPeriod,
            recentDrivingFrequency: payload?.recentDrivingFrequencyRawValue.flatMap(RecentDrivingFrequency.init(rawValue:)),
            selectedRoadDrivingExperiences: roadExperienceRawValues.compactMap(RoadDrivingExperience.init(rawValue:)),
            soloDrivingRange: payload?.soloDrivingRangeRawValue.flatMap(SoloDrivingRange.init(rawValue:)),
            soloParkingLevel: payload?.soloParkingLevelRawValue.flatMap(SoloParkingLevel.init(rawValue:))
        )
        preferences = .init(
            selectedPracticeSituations: payload?.practiceSituationRawValues.compactMap(PracticeSituation.init(rawValue:)) ?? [],
            vehicleType: payload?.vehicleTypeRawValue.flatMap(VehicleType.init(rawValue:))
        )
        drivingGoal = payload?.drivingGoal
        agreedSafetyItems = Set(payload?.agreedSafetyRawValues.compactMap(SafetyAgreement.init(rawValue:)) ?? [])
        requiresDrivingExperienceReselection = payload?.licenseDrivingPeriodRawValue != nil && drivingPeriod == nil
    }

    var isGuest: Bool {
        if case .guest = mode { return true }
        return false
    }

    var loginProvider: SocialLoginProvider? {
        if case .member(let provider) = mode { return provider }
        return nil
    }

    var entryMode: String {
        isGuest ? "guest" : loginProvider == nil ? "unknown" : "member"
    }

    func draftPayload(route: OnboardingRoute) -> OnboardingDraftPayload? {
        guard let loginProvider else { return nil }
        let experience = drivingExperience ?? .init()
        let preferences = preferences ?? .init()

        return .init(
            schemaVersion: 4,
            stepRawValue: route.rawValue,
            providerRawValue: loginProvider.rawValue,
            nickname: nickname ?? "",
            agreedTermsRawValues: agreedTerms.map(\.rawValue),
            agreedSafetyRawValues: agreedSafetyItems.map(\.rawValue),
            licenseDrivingPeriodRawValue: experience.licenseDrivingPeriod?.rawValue,
            recentDrivingFrequencyRawValue: experience.recentDrivingFrequency?.rawValue,
            roadDrivingExperienceRawValue: nil,
            roadDrivingExperienceRawValues: experience.selectedRoadDrivingExperiences.map(\.rawValue),
            soloDrivingRangeRawValue: experience.soloDrivingRange?.rawValue,
            soloParkingLevelRawValue: experience.soloParkingLevel?.rawValue,
            practiceSituationRawValues: preferences.selectedPracticeSituations.map(\.rawValue),
            vehicleTypeRawValue: preferences.vehicleType?.rawValue,
            drivingGoal: drivingGoal ?? ""
        )
    }

    static func initialRoute(payload: OnboardingDraftPayload?) -> OnboardingRoute? {
        let session = OnboardingSession(payload: payload)
        guard let payload, !payload.providerRawValue.isEmpty else { return nil }

        if payload.schemaVersion == 4,
           let route = OnboardingRoute(rawValue: payload.stepRawValue) {
            return session.requiresDrivingExperienceReselection ? .drivingExperience : route
        }

        if payload.schemaVersion == 3 {
            return routeFromLegacyStep(payload.stepRawValue, session: session)
        }

        if payload.schemaVersion == 2 {
            switch payload.stepRawValue {
            case 0: return nil
            case 1: return .terms
            case 2:
                if session.nickname?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false { return .nickname }
                return session.drivingExperience?.canProceed == true ? .optionalDrivingPreference : .drivingExperience
            case 3: return .safety
            default: return nil
            }
        }

        return routeFromLegacyStep(payload.stepRawValue, session: session)
    }

    private static func routeFromLegacyStep(
        _ rawValue: Int,
        session: OnboardingSession
    ) -> OnboardingRoute? {
        guard let legacy = OnboardingStep(rawValue: rawValue) else { return nil }
        return switch legacy {
        case .entry: nil
        case .terms: .terms
        case .nickname: .nickname
        case .drivingExperience: .drivingExperience
        case .optionalDrivingPreference: .optionalDrivingPreference
        case .safety: .safety
        case .locationPermission: .locationPermission
        }
    }
}

struct OnboardingTransition: Equatable {
    enum Navigation: Equatable {
        case push(OnboardingRoute)
        case pop
        case complete
    }

    let updatedSession: OnboardingSession
    let navigation: Navigation
}

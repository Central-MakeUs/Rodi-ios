//
//  OnboardingState.swift
//  Rodi
//
//  Created by mac on 7/1/26.
//

import Foundation

struct OnboardingState {
    var step: OnboardingStep = .entry
    var loginProvider: AuthProvider?
    var agreedTerms: Set<TermsAgreement> = []
    var agreedSafetyItems: Set<SafetyAgreement> = []
    var selectedTermsPage: TermsAgreement?
    var didComplete = false
    var isAuthenticating = false
    var loginAlertMessage: String?
    var isKakaoLoginMethodDialogPresented = false
    var isKakaoTalkFallbackAlertPresented = false
    var nickname = ""
    var licenseDrivingPeriod: LicenseDrivingPeriod?
    var recentDrivingFrequency: RecentDrivingFrequency?
    var selectedRoadDrivingExperiences: [RoadDrivingExperience] = []
    var soloDrivingRange: SoloDrivingRange?
    var soloParkingLevel: SoloParkingLevel?
    var selectedPracticeSituations: [PracticeSituation] = []
    var vehicleType: VehicleType?
    var drivingGoal = ""
    var isOnboardingAnalysisPresented = false
    var isOnboardingAnalysisCompletionPresented = false
    var onboardingAnalysis: MemberOnboardingAnalysis?

    var isAllTermsAgreed: Bool {
        agreedTerms.count == TermsAgreement.allCases.count
    }

    var isAllSafetyAgreed: Bool {
        agreedSafetyItems.count == SafetyAgreement.allCases.count
    }

    var canProceedFromDrivingExperience: Bool {
        let hasRequiredExperienceAnswers = licenseDrivingPeriod != nil
            && recentDrivingFrequency != nil
            && !selectedRoadDrivingExperiences.isEmpty

        guard hasRequiredExperienceAnswers else { return false }

        guard selectedRoadDrivingExperiences.contains(.soloPractice) else { return true }
        return soloDrivingRange != nil && soloParkingLevel != nil
    }

    var canProceedFromOptionalDrivingPreference: Bool {
        !selectedPracticeSituations.isEmpty && vehicleType != nil
    }

    var canProceedFromNickname: Bool {
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 로그인 완료 이후의 상태만 앱 종료 복원 대상으로 둡니다.
    var onboardingDraft: OnboardingDraftPayload? {
        guard let loginProvider, !didComplete else { return nil }

        return OnboardingDraftPayload(
            stepRawValue: step.rawValue,
            providerRawValue: loginProvider.rawValue,
            nickname: nickname,
            agreedTermsRawValues: agreedTerms.map(\.rawValue).sorted(),
            agreedSafetyRawValues: agreedSafetyItems.map(\.rawValue).sorted(),
            licenseDrivingPeriodRawValue: licenseDrivingPeriod?.rawValue,
            recentDrivingFrequencyRawValue: recentDrivingFrequency?.rawValue,
            roadDrivingExperienceRawValue: nil,
            roadDrivingExperienceRawValues: selectedRoadDrivingExperiences.map(\.rawValue),
            soloDrivingRangeRawValue: soloDrivingRange?.rawValue,
            soloParkingLevelRawValue: soloParkingLevel?.rawValue,
            practiceSituationRawValues: selectedPracticeSituations.map(\.rawValue),
            vehicleTypeRawValue: vehicleType?.rawValue,
            // 운전 목표는 앱을 닫아도 복원할 필요가 없는 임시 입력값입니다.
            drivingGoal: ""
        )
    }

    init() {}

    init(draft: OnboardingDraftPayload) {
        self.init()

        guard let step = OnboardingStep(rawValue: draft.stepRawValue),
              step != .entry,
              let provider = AuthProvider(rawValue: draft.providerRawValue)
        else {
            return
        }

        self.step = step
        loginProvider = provider
        nickname = draft.nickname
        agreedTerms = Set(draft.agreedTermsRawValues.compactMap(TermsAgreement.init(rawValue:)))
        agreedSafetyItems = Set(draft.agreedSafetyRawValues.compactMap(SafetyAgreement.init(rawValue:)))
        licenseDrivingPeriod = draft.licenseDrivingPeriodRawValue.flatMap(LicenseDrivingPeriod.init(rawValue:))
        recentDrivingFrequency = draft.recentDrivingFrequencyRawValue.flatMap(RecentDrivingFrequency.init(rawValue:))
        let roadExperienceRawValues = draft.roadDrivingExperienceRawValues
            ?? draft.roadDrivingExperienceRawValue.map { [$0] }
            ?? []
        selectedRoadDrivingExperiences = roadExperienceRawValues.compactMap(RoadDrivingExperience.init(rawValue:))
        soloDrivingRange = draft.soloDrivingRangeRawValue.flatMap(SoloDrivingRange.init(rawValue:))
        soloParkingLevel = draft.soloParkingLevelRawValue.flatMap(SoloParkingLevel.init(rawValue:))
        if !selectedRoadDrivingExperiences.contains(.soloPractice) {
            soloDrivingRange = nil
            soloParkingLevel = nil
        }
        selectedPracticeSituations = draft.practiceSituationRawValues.compactMap(PracticeSituation.init(rawValue:))
        vehicleType = draft.vehicleTypeRawValue.flatMap(VehicleType.init(rawValue:))
        drivingGoal = ""
    }
}

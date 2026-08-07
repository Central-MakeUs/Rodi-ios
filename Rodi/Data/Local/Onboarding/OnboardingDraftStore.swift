//
//  OnboardingDraftStore.swift
//  Rodi
//

import Foundation

/// 서버 온보딩 제출 전까지 사용자의 진행 단계와 선택값을 보관하는 로컬 초안입니다.
struct OnboardingDraftPayload: Codable, Equatable {
    let schemaVersion: Int?
    let stepRawValue: Int
    let providerRawValue: String
    let nickname: String
    let agreedTermsRawValues: [String]
    let agreedSafetyRawValues: [String]
    let licenseDrivingPeriodRawValue: String?
    let recentDrivingFrequencyRawValue: String?
    /// 이전 단일 선택 초안을 복원하기 위한 호환 필드입니다.
    let roadDrivingExperienceRawValue: String?
    let roadDrivingExperienceRawValues: [String]?
    let soloDrivingRangeRawValue: String?
    let soloParkingLevelRawValue: String?
    let practiceSituationRawValues: [String]
    let vehicleTypeRawValue: String?
    let drivingGoal: String

    init(
        schemaVersion: Int? = nil,
        stepRawValue: Int,
        providerRawValue: String,
        nickname: String,
        agreedTermsRawValues: [String],
        agreedSafetyRawValues: [String],
        licenseDrivingPeriodRawValue: String?,
        recentDrivingFrequencyRawValue: String?,
        roadDrivingExperienceRawValue: String?,
        roadDrivingExperienceRawValues: [String]?,
        soloDrivingRangeRawValue: String?,
        soloParkingLevelRawValue: String?,
        practiceSituationRawValues: [String],
        vehicleTypeRawValue: String?,
        drivingGoal: String
    ) {
        self.schemaVersion = schemaVersion
        self.stepRawValue = stepRawValue
        self.providerRawValue = providerRawValue
        self.nickname = nickname
        self.agreedTermsRawValues = agreedTermsRawValues
        self.agreedSafetyRawValues = agreedSafetyRawValues
        self.licenseDrivingPeriodRawValue = licenseDrivingPeriodRawValue
        self.recentDrivingFrequencyRawValue = recentDrivingFrequencyRawValue
        self.roadDrivingExperienceRawValue = roadDrivingExperienceRawValue
        self.roadDrivingExperienceRawValues = roadDrivingExperienceRawValues
        self.soloDrivingRangeRawValue = soloDrivingRangeRawValue
        self.soloParkingLevelRawValue = soloParkingLevelRawValue
        self.practiceSituationRawValues = practiceSituationRawValues
        self.vehicleTypeRawValue = vehicleTypeRawValue
        self.drivingGoal = drivingGoal
    }
}

/// 로그인한 신규 회원의 온보딩 초안을 기기에 단일 데이터로 저장합니다.
struct OnboardingDraftStore {
    private enum Key {
        static let onboardingDraft = "rodi.onboarding.draft"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> OnboardingDraftPayload? {
        do {
            guard let data = userDefaults.data(forKey: Key.onboardingDraft) else {
                return nil
            }
            return try JSONDecoder().decode(OnboardingDraftPayload.self, from: data)
        } catch {
            RodiLogger.warning("Failed to load onboarding draft: \(error.localizedDescription)")
            return nil
        }
    }

    func save(_ payload: OnboardingDraftPayload) {
        do {
            let data = try JSONEncoder().encode(payload)
            userDefaults.set(data, forKey: Key.onboardingDraft)
        } catch {
            RodiLogger.warning("Failed to save onboarding draft: \(error.localizedDescription)")
        }
    }

    func clear() {
        userDefaults.removeObject(forKey: Key.onboardingDraft)
    }
}

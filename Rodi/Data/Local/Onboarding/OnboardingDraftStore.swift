//
//  OnboardingDraftStore.swift
//  Rodi
//

import Foundation
import RealmSwift

/// 서버 온보딩 제출 전까지 사용자의 진행 단계와 선택값을 보관하는 로컬 초안입니다.
struct OnboardingDraftPayload: Codable, Equatable {
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
}

@objc(OnboardingDraftObject)
final class OnboardingDraftObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var payloadData: Data?
}

/// 로그인한 신규 회원의 온보딩 초안을 Realm에 단일 레코드로 저장합니다.
struct OnboardingDraftStore {
    private static let draftID = "current"

    func load() -> OnboardingDraftPayload? {
        do {
            let realm = try Realm()
            guard let data = realm.object(ofType: OnboardingDraftObject.self, forPrimaryKey: Self.draftID)?.payloadData else {
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
            let realm = try Realm()

            try realm.write {
                let object: OnboardingDraftObject
                if let existingObject = realm.object(ofType: OnboardingDraftObject.self, forPrimaryKey: Self.draftID) {
                    object = existingObject
                } else {
                    object = OnboardingDraftObject()
                    object.id = Self.draftID
                }
                object.payloadData = data
                realm.add(object, update: .modified)
            }
        } catch {
            RodiLogger.warning("Failed to save onboarding draft: \(error.localizedDescription)")
        }
    }

    func clear() {
        do {
            let realm = try Realm()
            guard let object = realm.object(ofType: OnboardingDraftObject.self, forPrimaryKey: Self.draftID) else {
                return
            }
            try realm.write {
                realm.delete(object)
            }
        } catch {
            RodiLogger.warning("Failed to clear onboarding draft: \(error.localizedDescription)")
        }
    }
}

//
//  AppPreferencesStore.swift
//  Rodi
//
//  Created by Codex on 6/27/26.
//

import Foundation
import RealmSwift

final class AppPreferenceObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var hasSeenOnboarding: Bool
}

struct AppPreferencesStore {
    private static let defaultID = "default"

    func hasSeenOnboarding() -> Bool {
        do {
            let realm = try Realm()
            return realm.object(ofType: AppPreferenceObject.self, forPrimaryKey: Self.defaultID)?.hasSeenOnboarding ?? false
        } catch {
            return false
        }
    }

    func markOnboardingSeen() {
        do {
            let realm = try Realm()
            try realm.write {
                let object: AppPreferenceObject
                if let existingObject = realm.object(ofType: AppPreferenceObject.self, forPrimaryKey: Self.defaultID) {
                    object = existingObject
                } else {
                    object = AppPreferenceObject()
                    object.id = Self.defaultID
                }
                object.hasSeenOnboarding = true
                realm.add(object, update: .modified)
            }
        } catch {
            assertionFailure("Failed to write onboarding preference: \(error)")
        }
    }

    func resetOnboardingSeen() {
        do {
            let realm = try Realm()
            try realm.write {
                let object: AppPreferenceObject
                if let existingObject = realm.object(ofType: AppPreferenceObject.self, forPrimaryKey: Self.defaultID) {
                    object = existingObject
                } else {
                    object = AppPreferenceObject()
                    object.id = Self.defaultID
                }
                object.hasSeenOnboarding = false
                realm.add(object, update: .modified)
            }
        } catch {
            assertionFailure("Failed to reset onboarding preference: \(error)")
        }
    }
}

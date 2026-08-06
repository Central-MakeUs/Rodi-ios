//
//  HomePracticeFilterStore.swift
//  Rodi
//

import Foundation

struct HomePracticeFilterStore {
    private enum Key {
        static let selection = "rodi.home.practice-filter-selection"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> HomePracticeFilterSelection {
        guard let data = userDefaults.data(forKey: Key.selection),
              let selection = try? JSONDecoder().decode(HomePracticeFilterSelection.self, from: data)
        else {
            return .default
        }
        return selection
    }

    func save(_ selection: HomePracticeFilterSelection) {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        userDefaults.set(data, forKey: Key.selection)
    }
}

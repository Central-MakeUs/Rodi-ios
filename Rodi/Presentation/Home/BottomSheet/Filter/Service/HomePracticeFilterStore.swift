//
//  HomePracticeFilterStore.swift
//  Rodi
//

import Foundation

struct HomePracticeFilterStore {
    private enum Key {
        static let selection = "rodi.home.practice-filter-selection"
    }

    private let persistence = UserDefaultsCodableStore<HomePracticeFilterSelection>(key: Key.selection)

    func load() -> HomePracticeFilterSelection {
        persistence.load() ?? .default
    }

    func save(_ selection: HomePracticeFilterSelection) {
        persistence.save(selection)
    }
}

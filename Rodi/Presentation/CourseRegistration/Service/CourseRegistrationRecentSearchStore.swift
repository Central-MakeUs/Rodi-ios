import Foundation

struct CourseRegistrationRecentSearch: Codable, Equatable, Identifiable {
    enum Kind: String, Codable {
        case region
        case place
    }

    let id: UUID
    let title: String
    let kind: Kind
    let coordinate: RodiCoordinate?
}

struct CourseRegistrationRecentSearchStore {
    private enum Key {
        static let searches = "course_registration_recent_searches"
        static let maximumCount = 15
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> [CourseRegistrationRecentSearch] {
        guard let data = userDefaults.data(forKey: Key.searches),
              let searches = try? JSONDecoder().decode([CourseRegistrationRecentSearch].self, from: data)
        else {
            return []
        }
        return searches
    }

    func save(_ search: CourseRegistrationRecentSearch) -> [CourseRegistrationRecentSearch] {
        var searches = load()
        searches.removeAll { $0.kind == search.kind && $0.title == search.title }
        searches.insert(search, at: 0)
        searches = Array(searches.prefix(Key.maximumCount))
        persist(searches)
        return searches
    }

    func remove(id: UUID) -> [CourseRegistrationRecentSearch] {
        let searches = load().filter { $0.id != id }
        persist(searches)
        return searches
    }

    func removeAll() {
        userDefaults.removeObject(forKey: Key.searches)
    }

    private func persist(_ searches: [CourseRegistrationRecentSearch]) {
        guard let data = try? JSONEncoder().encode(searches) else { return }
        userDefaults.set(data, forKey: Key.searches)
    }
}

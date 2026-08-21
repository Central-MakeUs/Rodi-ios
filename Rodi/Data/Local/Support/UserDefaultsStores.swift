import Foundation

/// Data/Local이 소유하는 Codable payload 저장 표현이다.
/// 저장 key와 값의 정책은 호출 Feature가 결정한다.
struct UserDefaultsCodableStore<Value: Codable> {
    private let key: String
    private let userDefaults: UserDefaults

    init(key: String, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.userDefaults = userDefaults
    }

    func load() -> Value? {
        try? decode()
    }

    func decode() throws -> Value? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(Value.self, from: data)
    }

    func save(_ value: Value) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        userDefaults.set(data, forKey: key)
    }

    func remove() {
        userDefaults.removeObject(forKey: key)
    }
}

struct UserDefaultsStringStore {
    private let key: String
    private let userDefaults: UserDefaults

    init(key: String, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.userDefaults = userDefaults
    }

    func load() -> String? {
        userDefaults.string(forKey: key)
    }

    func save(_ value: String) {
        userDefaults.set(value, forKey: key)
    }

    func remove() {
        userDefaults.removeObject(forKey: key)
    }
}

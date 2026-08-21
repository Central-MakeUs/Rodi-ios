import Foundation

enum HomeSearchDisplayName {
    static func region(_ name: String) -> String {
        name
            .replacingOccurrences(of: "특별시", with: "")
            .replacingOccurrences(of: "광역시", with: "")
    }
}

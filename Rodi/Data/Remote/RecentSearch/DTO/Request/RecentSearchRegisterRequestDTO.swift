import Foundation

struct RecentSearchRegisterRequestDTO: Encodable {
    let type: String
    let keyword: String
    let placeId: Int?
}

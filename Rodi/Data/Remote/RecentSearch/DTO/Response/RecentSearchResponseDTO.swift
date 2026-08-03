import Foundation

struct RecentSearchDTO: Decodable {
    let id: Int
    let type: String
    let keyword: String
    let placeId: Int?
}

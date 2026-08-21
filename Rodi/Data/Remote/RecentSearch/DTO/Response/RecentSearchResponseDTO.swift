import Foundation

struct RecentSearchDTO: Decodable {
    let id: Int64
    let type: String
    let keyword: String
    let placeId: Int?
}

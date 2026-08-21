import Foundation

struct ReviewCreateResponseDTO: Decodable {
    let reviewID: Int64

    private enum CodingKeys: String, CodingKey {
        case reviewID = "reviewId"
    }
}

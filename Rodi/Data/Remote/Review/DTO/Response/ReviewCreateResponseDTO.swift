import Foundation

struct ReviewCreateResponseDTO: Decodable {
    let reviewID: Int

    private enum CodingKeys: String, CodingKey {
        case reviewID = "reviewId"
    }
}

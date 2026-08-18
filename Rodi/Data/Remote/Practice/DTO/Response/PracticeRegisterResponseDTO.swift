import Foundation

struct PracticeRegisterResponseDTO: Decodable {
    let practiceID: Int
    let status: String?
    let visitCount: Int?
    let requiredDistanceMeters: Int?

    private enum CodingKeys: String, CodingKey {
        case practiceID = "practiceId"
        case status
        case visitCount
        case requiredDistanceMeters
    }
}

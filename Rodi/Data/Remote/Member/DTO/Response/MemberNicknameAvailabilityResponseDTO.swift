import Foundation

struct MemberNicknameAvailabilityResponseDTO: Decodable {
    let nickname: String
    let available: Bool
    let reason: String?
    let message: String?
    let nicknameChangeableAt: String?
}

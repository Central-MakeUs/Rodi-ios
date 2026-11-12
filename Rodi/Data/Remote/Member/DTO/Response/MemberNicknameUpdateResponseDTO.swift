import Foundation

struct MemberNicknameUpdateResponseDTO: Decodable {
    let nickname: String
    let nicknameChangeableAt: String?
}

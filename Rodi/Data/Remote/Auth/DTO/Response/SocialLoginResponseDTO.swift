import Foundation

struct SocialLoginResponseDTO: Decodable {
    enum Status: String, Decodable {
        case success = "SUCCESS"
        case withdrawalPending = "WITHDRAWAL_PENDING"
    }
    let status: Status
    let accessToken: String?
    let refreshToken: String?
    let isNewMember: Bool?
    let nickname: String?
    let withdrawalRequestedAt: String?
    let recoverableUntil: String?
}

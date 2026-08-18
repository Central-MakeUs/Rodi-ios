import Foundation

struct SocialLoginResponseDTO: Decodable {
    enum Status: String, Decodable {
        case success = "SUCCESS"
        case withdrawalPending = "WITHDRAWAL_PENDING"
        case withdrawalLocked = "WITHDRAWAL_LOCKED"
    }
    let status: Status
    let accessToken: String?
    let refreshToken: String?
    let isNewMember: Bool?
    let isOnboarded: Bool?
    let isCourseTutorialCompleted: Bool?
    let nickname: String?
    let withdrawalRequestedAt: String?
    let recoverableUntil: String?
    let reRegisterableAt: String?
}

import Foundation

struct AuthTokenDTO: Decodable {
    let accessToken: String
    let refreshToken: String
    let isNewMember: Bool
}

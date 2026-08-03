import Foundation

extension MemberProfileResponseDTO {
    func toDomain() throws(
        NetworkError
    ) -> MemberProfile {
        guard let level = MemberProfile.Level(
            rawValue: level
        ) else {
            throw .decodingFail
        }
        return MemberProfile(
            nickname: nickname,
            level: level,
            recommendationTags: recommendationTags,
            drivingGoal: drivingGoal,
            savedPlaceCount: savedPlaceCount
        )
    }
}

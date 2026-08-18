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
            savedPlaceCount: try int(from: savedPlaceCount),
            levelProgress: levelProgress.map(MemberProfile.LevelProgress.init)
        )
    }

    private func int(from value: Int64) throws(NetworkError) -> Int {
        guard let value = Int(exactly: value) else {
            throw .decodingFail
        }
        return value
    }
}

private extension MemberProfile.LevelProgress {
    init(_ dto: LevelProgressResponseDTO) {
        self.init(
            totalDistanceKm: dto.totalDistanceKm,
            currentLevelStartKm: dto.currentLevelStartKm,
            nextLevelKm: dto.nextLevelKm,
            progressPercent: dto.progressPercent
        )
    }
}

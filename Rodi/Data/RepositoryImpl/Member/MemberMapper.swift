import Foundation

nonisolated enum MemberMapper {
    static func drivingGoalRequest(
        from drivingGoal: String
    ) -> MemberDrivingGoalUpdateRequestDTO {
        .init(drivingGoal: drivingGoal)
    }

    static func placeFilterTagsRequest(
        from tags: [PlacePracticeType]
    ) -> MemberPlaceFilterTagsUpdateRequestDTO {
        .init(filterTags: tags.map(\.rawValue))
    }

    static func onboardingRequest(
        from submission: MemberOnboardingSubmission
    ) -> MemberOnboardingRequestDTO {
        .init(
            drivingPeriod: submission.drivingPeriod.rawValue,
            recentFrequency: submission.recentFrequency?.rawValue,
            roadExperiences: submission.roadExperiences.isEmpty
                ? nil
                : submission.roadExperiences.map(\.rawValue),
            soloDrivingRange: submission.soloDrivingRange?.rawValue,
            soloParkingLevel: submission.soloParkingLevel?.rawValue,
            level: submission.level.rawValue,
            practiceTypes: submission.practiceTypes.isEmpty
                ? nil
                : submission.practiceTypes.map(\.rawValue),
            carType: submission.carType?.rawValue,
            drivingGoal: submission.drivingGoal
        )
    }

    static func profile(
        from dto: MemberProfileResponseDTO
    ) throws(NetworkError) -> MemberProfile {
        guard let level = MemberProfile.Level(
            rawValue: dto.level
        ) else {
            throw .decodingFail
        }
        return MemberProfile(
            nickname: dto.nickname,
            level: level,
            recommendationTags: dto.recommendationTags,
            drivingGoal: dto.drivingGoal,
            savedPlaceCount: try int(from: dto.savedPlaceCount),
            levelProgress: dto.levelProgress.map(MemberProfile.LevelProgress.init)
        )
    }

    static func blockedMemberPage(
        from dto: BlockedMemberCursorPageResponseDTO
    ) throws(NetworkError) -> BlockedMemberPage {
        .init(
            items: try dto.items.map(blockedMember(from:)),
            hasNext: dto.hasNext,
            nextCursor: dto.nextCursor,
            totalCount: try dto.totalCount.map(int(from:))
        )
    }

    static func blockedMember(
        from dto: BlockedMemberItemResponseDTO
    ) throws(NetworkError) -> BlockedMember {
        guard let blockedAt = ServerDateParser.date(from: dto.blockedAt) else {
            throw .decodingFail
        }

        return .init(
            id: try int(from: dto.memberId),
            nickname: dto.nickname,
            blockedAt: blockedAt
        )
    }

    static func int(from value: Int64) throws(NetworkError) -> Int {
        guard let value = Int(exactly: value) else {
            throw .decodingFail
        }
        return value
    }

}

nonisolated extension BlockedMemberListQueryDTO {
    init(_ query: BlockedMemberQuery) {
        self.init(size: query.size, cursor: query.cursor)
    }
}

nonisolated private extension MemberProfile.LevelProgress {
    init(_ dto: LevelProgressResponseDTO) {
        self.init(
            totalDistanceKm: dto.totalDistanceKm,
            currentLevelStartKm: dto.currentLevelStartKm,
            nextLevelKm: dto.nextLevelKm,
            progressPercent: dto.progressPercent
        )
    }
}

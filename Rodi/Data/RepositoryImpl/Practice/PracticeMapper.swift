import Foundation

nonisolated enum PracticeMapper {
    static func registration(
        from dto: PracticeRegisterResponseDTO
    ) throws(NetworkError) -> PracticeRegistration {
        .init(
            practiceID: try int(from: dto.practiceID),
            status: dto.status,
            visitCount: dto.visitCount,
            requiredDistanceMeters: dto.requiredDistanceMeters
        )
    }

    static func visit(
        from dto: PracticeVisitResponseDTO
    ) throws(NetworkError) -> PracticeVisit {
        let newLevel: MemberProfile.Level?
        if let rawLevel = dto.newLevel {
            guard let level = MemberProfile.Level(rawValue: rawLevel) else {
                throw .decodingFail
            }
            newLevel = level
        } else {
            newLevel = nil
        }

        return .init(
            visitCount: dto.visitCount,
            addedCertifiedDistanceMeters: dto.addedCertifiedDistanceMeters,
            requiredDistanceMeters: dto.requiredDistanceMeters,
            isCertifiedNow: dto.isCertifiedNow,
            totalDistanceKm: dto.totalDistanceKm,
            levelUp: dto.levelUp,
            newLevel: newLevel
        )
    }

    static func myPracticePage(
        from dto: MyPracticeCursorPageResponseDTO
    ) throws(NetworkError) -> MyPracticePage {
        .init(
            items: try dto.items
                .map(myPracticeItem(from:))
                .filter { !$0.isDeleted },
            hasNext: dto.hasNext,
            nextCursor: dto.nextCursor,
            totalCount: try dto.totalCount.map(int(from:))
        )
    }

    static func skipReasonForm(
        from dto: PracticeSkipReasonFormResponseDTO
    ) -> PracticeSkipReasonForm {
        .init(
            questionID: dto.questionID,
            type: dto.type,
            title: dto.title,
            description: dto.description,
            isRequired: dto.required,
            options: dto.options
                .sorted { $0.order < $1.order }
                .map(skipReasonOption(from:))
        )
    }

    private static func myPracticeItem(
        from dto: MyPracticeItemResponseDTO
    ) throws(NetworkError) -> MyPracticeItem {
        guard let status = MyPracticeStatus(rawValue: dto.status) else {
            throw .decodingFail
        }

        return .init(
            id: try int(from: dto.practiceId),
            placeID: try int(from: dto.placeId),
            placeName: dto.placeName,
            practiceTypes: dto.practiceTypes,
            status: status,
            visitCount: dto.visitCount,
            lastActivityAt: ServerDateParser.date(from: dto.lastActivityAt),
            hasReview: dto.hasReview,
            isDeleted: dto.isDeleted ?? false
        )
    }

    private static func skipReasonOption(
        from dto: PracticeSkipReasonOptionDTO
    ) -> PracticeSkipReasonOption {
        .init(
            code: dto.code,
            label: dto.label,
            order: dto.order,
            requiresTextInput: dto.requiresTextInput,
            textInputPlaceholder: dto.textInputPlaceholder,
            textInputMaxLength: dto.textInputMaxLength
        )
    }

    private static func int(from value: Int64) throws(NetworkError) -> Int {
        guard let value = Int(exactly: value) else {
            throw .decodingFail
        }
        return value
    }

}

nonisolated extension MyPracticeListQueryDTO {
    init(_ query: MyPracticeQuery) {
        self.init(size: query.size, cursor: query.cursor)
    }
}

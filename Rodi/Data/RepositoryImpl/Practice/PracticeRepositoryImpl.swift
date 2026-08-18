import Foundation

final class PracticeRepositoryImpl: PracticeRepository {
    private let remoteDataSource: PracticeRemoteDataSource

    init(remoteDataSource: PracticeRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func register(placeID: Int) async throws(NetworkError) -> PracticeRegistration {
        let response = try await remoteDataSource.register(placeID: placeID)
        return .init(
            practiceID: response.practiceID,
            status: response.status,
            visitCount: response.visitCount,
            requiredDistanceMeters: response.requiredDistanceMeters
        )
    }

    func recordVisit(practiceID: Int, certifiedDistanceMeters: Int?) async throws(NetworkError) -> PracticeVisit {
        let response = try await remoteDataSource.recordVisit(
            practiceID: practiceID,
            certifiedDistanceMeters: certifiedDistanceMeters
        )
        let newLevel: MemberProfile.Level?
        if let rawLevel = response.newLevel {
            guard let level = MemberProfile.Level(rawValue: rawLevel) else {
                throw .decodingFail
            }
            newLevel = level
        } else {
            newLevel = nil
        }

        return .init(
            visitCount: response.visitCount,
            addedCertifiedDistanceMeters: response.addedCertifiedDistanceMeters,
            requiredDistanceMeters: response.requiredDistanceMeters,
            isCertifiedNow: response.isCertifiedNow,
            totalDistanceKm: response.totalDistanceKm,
            levelUp: response.levelUp,
            newLevel: newLevel
        )
    }

    func fetchMyPractices(query: MyPracticeQuery) async throws(NetworkError) -> MyPracticePage {
        try myPracticePage(from: await remoteDataSource.fetchMyPractices(query: query))
    }

    func fetchSkipReasonForm() async throws(NetworkError) -> PracticeSkipReasonForm {
        let response = try await remoteDataSource.fetchSkipReasonForm()
        return .init(
            questionID: response.questionID,
            type: response.type,
            title: response.title,
            description: response.description,
            isRequired: response.required,
            options: response.options
                .sorted { $0.order < $1.order }
                .map(PracticeSkipReasonOption.init)
        )
    }

    func submitSkipReason(
        practiceID: Int,
        reasonCode: String,
        detail: String?
    ) async throws(NetworkError) {
        try await remoteDataSource.submitSkipReason(
            practiceID: practiceID,
            reasonCode: reasonCode,
            detail: detail
        )
    }
}

private extension PracticeRepositoryImpl {

    func myPracticePage(from dto: MyPracticeCursorPageResponseDTO) throws(NetworkError) -> MyPracticePage {
        .init(
            items: try dto.items
                .map(myPracticeItem(from:))
                .filter { !$0.isDeleted },
            hasNext: dto.hasNext,
            nextCursor: dto.nextCursor,
            totalCount: try dto.totalCount.map(int(from:))
        )
    }

    func myPracticeItem(from dto: MyPracticeItemResponseDTO) throws(NetworkError) -> MyPracticeItem {
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
            lastActivityAt: dto.lastActivityAt.flatMap(date(from:)),
            hasReview: dto.hasReview,
            isDeleted: dto.isDeleted ?? false
        )
    }

    func int(from value: Int64) throws(NetworkError) -> Int {
        guard let value = Int(exactly: value) else {
            throw .decodingFail
        }
        return value
    }

    func date(from value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        for format in [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss"
        ] {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }

        return ISO8601DateFormatter().date(from: value)
    }
}

private extension PracticeSkipReasonOption {

    init(_ response: PracticeSkipReasonOptionDTO) {
        self.init(
            code: response.code,
            label: response.label,
            order: response.order,
            requiresTextInput: response.requiresTextInput,
            textInputPlaceholder: response.textInputPlaceholder,
            textInputMaxLength: response.textInputMaxLength
        )
    }
}

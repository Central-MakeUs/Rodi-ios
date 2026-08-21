import Foundation

final class PracticeRepositoryImpl: PracticeRepository {
    private let remoteDataSource: PracticeRemoteDataSource

    init(remoteDataSource: PracticeRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func register(placeID: Int) async throws(NetworkError) -> PracticeRegistration {
        try PracticeMapper.registration(
            from: try await remoteDataSource.register(placeID: placeID)
        )
    }

    func recordVisit(practiceID: Int, certifiedDistanceMeters: Int?) async throws(NetworkError) -> PracticeVisit {
        try PracticeMapper.visit(
            from: await remoteDataSource.recordVisit(
            practiceID: practiceID,
            request: .init(certifiedDistanceMeters: certifiedDistanceMeters)
            )
        )
    }

    func fetchMyPractices(query: MyPracticeQuery) async throws(NetworkError) -> MyPracticePage {
        try PracticeMapper.myPracticePage(
            from: await remoteDataSource.fetchMyPractices(query: .init(query))
        )
    }

    func fetchSkipReasonForm() async throws(NetworkError) -> PracticeSkipReasonForm {
        PracticeMapper.skipReasonForm(
            from: try await remoteDataSource.fetchSkipReasonForm()
        )
    }

    func submitSkipReason(
        practiceID: Int,
        reasonCode: String,
        detail: String?
    ) async throws(NetworkError) {
        try await remoteDataSource.submitSkipReason(
            practiceID: practiceID,
            request: .init(reasonCode: reasonCode, detail: detail)
        )
    }
}

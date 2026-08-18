import Foundation

final class CourseRepositoryImpl: CourseRepository {
    private let remoteDataSource: CourseRemoteDataSource

    init(remoteDataSource: CourseRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchRegistrationForm() async throws(NetworkError) -> CourseRegistrationForm {
        let dto = try await remoteDataSource.fetchRegistrationForm()
        return .init(
            maxWaypoints: dto.maxWaypoints,
            sections: .init(
                basicInfo: dto.sections.basicInfo,
                practiceCategory: dto.sections.practiceCategory,
                practiceType: dto.sections.practiceType,
                caution: dto.sections.caution,
                description: dto.sections.description
            ),
            practiceType: .init(
                maxSelect: dto.practiceType.maxSelect,
                maxSelectExceededMessage: dto.practiceType.maxSelectExceededMessage,
                categories: dto.practiceType.categories
                    .sorted { $0.order < $1.order }
                    .map { category in
                        .init(
                            code: category.code,
                            label: category.label,
                            order: category.order,
                            practiceTypes: category.practiceTypes
                                .sorted { $0.order < $1.order }
                                .map { .init(code: $0.code, label: $0.label, order: $0.order) }
                        )
                    }
            ),
            inputs: .init(
                caution: textInput(from: dto.inputs.caution),
                description: textInput(from: dto.inputs.description)
            )
        )
    }

    func register(_ submission: CourseRegistrationSubmission) async throws(NetworkError) -> CourseRegistrationResult {
        let response = try await remoteDataSource.register(submission)
        guard let courseID = Int(exactly: response.courseId) else {
            throw .decodingFail
        }
        return .init(courseID: courseID, approvalStatus: response.approvalStatus)
    }

    func fetchMyCourses(query: MyCourseQuery) async throws(NetworkError) -> MyCoursePage {
        let dto = try await remoteDataSource.fetchMyCourses(query: query)
        return try .init(
            items: dto.items.map(myCourseItem(from:)),
            hasNext: dto.hasNext,
            nextCursor: dto.nextCursor,
            totalCount: dto.totalCount.map(int(from:))
        )
    }

    func deleteMyCourse(courseID: Int64) async throws(NetworkError) {
        try await remoteDataSource.deleteMyCourse(courseID: courseID)
    }

    private func textInput(from dto: CourseInputSpecDTO) -> CourseRegistrationTextInputSpec {
        .init(
            required: dto.required,
            minLength: dto.minLength,
            maxLength: dto.maxLength,
            placeholder: dto.placeholder
        )
    }

    func myCourseItem(from dto: MyCourseItemResponseDTO) throws(NetworkError) -> MyCourseItem {
        guard let approvalStatus = MyCourseApprovalStatus(rawValue: dto.approvalStatus)
        else {
            throw .decodingFail
        }

        return .init(
            id: dto.courseId,
            name: dto.name,
            approvalStatus: approvalStatus,
            createdAt: dto.createdAt
        )
    }

    func int(from value: Int64) throws(NetworkError) -> Int {
        guard let value = Int(exactly: value) else {
            throw .decodingFail
        }
        return value
    }

}

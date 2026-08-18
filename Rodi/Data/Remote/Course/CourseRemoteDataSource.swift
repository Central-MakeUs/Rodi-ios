import Foundation

final class CourseRemoteDataSource {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func fetchRegistrationForm() async throws(NetworkError) -> CourseRegistrationFormResponseDTO {
        try await request(.registrationForm, as: CourseRegistrationFormResponseDTO.self)
    }

    func register(_ submission: CourseRegistrationSubmission) async throws(NetworkError) -> CourseRegisterResponseDTO {
        try await request(.register(.init(submission)), as: CourseRegisterResponseDTO.self)
    }

    func fetchMyCourses(query: MyCourseQuery) async throws(NetworkError) -> MyCourseCursorPageResponseDTO {
        try await request(
            .myCourses(.init(status: query.status?.rawValue, size: query.size, cursor: query.cursor)),
            as: MyCourseCursorPageResponseDTO.self
        )
    }

    func deleteMyCourse(courseID: Int64) async throws(NetworkError) {
        let response = try await networkManager.request(
            CourseAPI.deleteMyCourse(courseID: courseID),
            as: ServerResponse<EmptyResponse>.self
        )
        guard response.isSuccess else {
            throw .apiError(code: response.code, message: response.message)
        }
    }

    private func request<T: Decodable>(_ api: CourseAPI, as type: T.Type) async throws(NetworkError) -> T {
        let response = try await networkManager.request(api, as: ServerResponse<T>.self)
        guard response.isSuccess, let data = response.data else {
            throw .apiError(code: response.code, message: response.message)
        }
        return data
    }
}

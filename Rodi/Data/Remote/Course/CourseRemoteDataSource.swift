import Foundation

final class CourseRemoteDataSource {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func fetchRegistrationForm() async throws(NetworkError) -> CourseRegistrationFormResponseDTO {
        try await ServerResponseHandler.payload(
            CourseAPI.registrationForm,
            using: networkManager,
            as: CourseRegistrationFormResponseDTO.self
        )
    }

    func register(
        _ registrationRequest: CourseRegisterRequestDTO
    ) async throws(NetworkError) -> CourseRegisterResponseDTO {
        try await ServerResponseHandler.payload(
            CourseAPI.register(registrationRequest),
            using: networkManager,
            as: CourseRegisterResponseDTO.self
        )
    }

    func fetchMyCourses(query: MyCourseListQueryDTO) async throws(NetworkError) -> MyCourseCursorPageResponseDTO {
        try await ServerResponseHandler.payload(
            CourseAPI.myCourses(query),
            using: networkManager,
            as: MyCourseCursorPageResponseDTO.self
        )
    }

    func deleteMyCourse(courseID: Int64) async throws(NetworkError) {
        try await ServerResponseHandler.empty(
            CourseAPI.deleteMyCourse(courseID: courseID),
            using: networkManager
        )
    }
}

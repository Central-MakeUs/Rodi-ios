import Foundation

final class CourseRepositoryImpl: CourseRepository {
    private let remoteDataSource: CourseRemoteDataSource

    init(remoteDataSource: CourseRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchRegistrationForm() async throws(NetworkError) -> CourseRegistrationForm {
        CourseMapper.registrationForm(
            from: try await remoteDataSource.fetchRegistrationForm()
        )
    }

    func register(_ submission: CourseRegistrationSubmission) async throws(NetworkError) -> CourseRegistrationResult {
        try CourseMapper.registrationResult(
            from: await remoteDataSource.register(
                .init(submission)
            )
        )
    }

    func fetchMyCourses(query: MyCourseQuery) async throws(NetworkError) -> MyCoursePage {
        try CourseMapper.myCoursePage(
            from: await remoteDataSource.fetchMyCourses(
                query: .init(query)
            )
        )
    }

    func deleteMyCourse(courseID: Int64) async throws(NetworkError) {
        try await remoteDataSource.deleteMyCourse(courseID: courseID)
    }

}

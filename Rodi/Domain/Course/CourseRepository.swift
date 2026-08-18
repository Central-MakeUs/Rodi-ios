import Foundation

protocol CourseRepository {
    func fetchRegistrationForm() async throws(NetworkError) -> CourseRegistrationForm
    func register(_ submission: CourseRegistrationSubmission) async throws(NetworkError) -> CourseRegistrationResult
    func fetchMyCourses(query: MyCourseQuery) async throws(NetworkError) -> MyCoursePage
    func deleteMyCourse(courseID: Int64) async throws(NetworkError)
}

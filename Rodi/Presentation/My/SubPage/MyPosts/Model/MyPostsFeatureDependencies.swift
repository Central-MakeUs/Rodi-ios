//
//  MyPostsFeatureDependencies.swift
//  Rodi
//

struct MyPostsFeatureDependencies {
    let reviewRepository: ReviewRepository
    let practiceRepository: PracticeRepository
    let courseRepository: CourseRepository

    init(
        reviewRepository: ReviewRepository,
        practiceRepository: PracticeRepository,
        courseRepository: CourseRepository
    ) {
        self.reviewRepository = reviewRepository
        self.practiceRepository = practiceRepository
        self.courseRepository = courseRepository
    }
}

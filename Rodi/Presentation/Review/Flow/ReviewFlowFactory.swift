//
//  ReviewFlowFactory.swift
//  Rodi
//

import Foundation

/// 후기 flow 내부 reducer와 feature service를 조립한다.
enum ReviewFlowFactory {

    static func make(
        placeRepository: PlaceRepository,
        practiceRepository: PracticeRepository,
        reviewRepository: ReviewRepository,
        usesServerReviewForm: Bool
    ) -> ReviewFlowCoordinatorReducer {
        let reviewReducer = ReviewReducer(
            promptService: ReviewPromptService(
                placeRepository: placeRepository,
                practiceRepository: practiceRepository
            ),
            writingService: ReviewWritingService(
                reviewRepository: reviewRepository,
                usesServerForm: usesServerReviewForm
            ),
            skipReasonService: ReviewSkipReasonService(practiceRepository: practiceRepository)
        )

        return ReviewFlowCoordinatorReducer(reviewReducer: reviewReducer)
    }
}

import Foundation

protocol ReviewPromptServicing {
    func prepareTarget(placeID: Int) async throws -> ReviewTarget
}

struct ReviewPromptService: ReviewPromptServicing {
    private let placeRepository: PlaceRepository
    private let practiceRepository: PracticeRepository

    init(
        placeRepository: PlaceRepository,
        practiceRepository: PracticeRepository
    ) {
        self.placeRepository = placeRepository
        self.practiceRepository = practiceRepository
    }

    func prepareTarget(placeID: Int) async throws -> ReviewTarget {
        let place: PlaceDetail
        do {
            place = try await placeRepository.fetchPlaceDetail(id: placeID)
        } catch let error {
            throw ReviewTargetPreparationError.placeDetail(placeID: placeID, error: error)
        }

        do {
            let practice = try await practiceRepository.register(placeID: place.id)
            return .init(
                placeID: place.id,
                practiceID: practice.practiceID,
                placeName: place.name
            )
        } catch let error {
            throw ReviewTargetPreparationError.practiceRegistration(placeID: place.id, error: error)
        }
    }

}

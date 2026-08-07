//
//  MapService.swift
//  Rodi
//

import Foundation

enum MapServiceInAction {
    case requestCurrentLocation(source: LocationRequestSource)
    case loadPlaceCoordinates
}

enum MapServiceOutAction {
    case currentLocationResolved(RodiCoordinate)
    case currentLocationUnavailable(source: LocationRequestSource)
    case currentLocationPermissionDenied(source: LocationRequestSource)
    case userHeadingUpdated(Double)
    case placeCoordinatesLoaded([PlaceCoordinate])
    case placeCoordinatesLoadFailed
}

/// 위치 요청, 장소 좌표
@MainActor
final class MapService {
    private let placeRepository: PlaceRepository
    private let locationService: MapLocationService

    init(
        placeRepository: PlaceRepository,
        locationService: MapLocationService
    ) {
        self.placeRepository = placeRepository
        self.locationService = locationService
    }

    func perform(_ action: MapServiceInAction) async -> MapServiceOutAction? {
        switch action {
        case .requestCurrentLocation(let source):
            switch await locationService.requestLocation() {
            case .resolved(let coordinate):
                return .currentLocationResolved(coordinate)

            case .unavailable:
                return .currentLocationUnavailable(source: source)

            case .permissionDenied:
                return .currentLocationPermissionDenied(source: source)
            }

        case .loadPlaceCoordinates:
            do {
                return .placeCoordinatesLoaded(
                    try await placeRepository.fetchCoordinates()
                )
            } catch is CancellationError {
                return nil
            } catch {
                return .placeCoordinatesLoadFailed
            }
        }
    }

    func userHeadingUpdates() -> AsyncStream<Double> {
        locationService.headingUpdates()
    }
}

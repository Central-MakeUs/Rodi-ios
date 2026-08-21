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
    case currentLocationResolved(RodiCoordinate, source: LocationRequestSource)
    case currentLocationUnavailable(source: LocationRequestSource)
    case currentLocationPermissionDenied(
        source: LocationRequestSource,
        authorizationState: LocationAuthorizationState
    )
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

    var locationAuthorizationState: LocationAuthorizationState {
        locationService.authorizationState
    }

    func perform(_ action: MapServiceInAction) async -> MapServiceOutAction? {
        switch action {
        case .requestCurrentLocation(let source):
            switch await locationService.requestLocation() {
            case .resolved(let coordinate):
                return .currentLocationResolved(coordinate, source: source)

            case .unavailable:
                return .currentLocationUnavailable(source: source)

            case .permissionDenied(let authorizationState):
                return .currentLocationPermissionDenied(
                    source: source,
                    authorizationState: authorizationState
                )
            }

        case .loadPlaceCoordinates:
            do {
                return .placeCoordinatesLoaded(
                    try await placeRepository.fetchCoordinates()
                )
            } catch {
                guard !Task.isCancelled else { return nil }
                return .placeCoordinatesLoadFailed
            }
        }
    }

    func userHeadingUpdates() -> AsyncStream<Double> {
        locationService.headingUpdates()
    }
}

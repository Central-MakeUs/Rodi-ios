//
//  MapService.swift
//  Rodi
//

import Foundation

enum MapServiceInAction {
    case requestCurrentLocation(source: LocationRequestSource)
    case loadClusters(PlaceClusterQuery, revision: Int)
}

enum MapServiceOutAction {
    case currentLocationResolved(RodiCoordinate, source: LocationRequestSource)
    case currentLocationUnavailable(source: LocationRequestSource)
    case currentLocationPermissionDenied(
        source: LocationRequestSource,
        authorizationState: LocationAuthorizationState
    )
    case userHeadingUpdated(Double)
    case clustersLoaded(PlaceClusterResult, revision: Int)
    case clusterLoadFailed(revision: Int)
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

        case let .loadClusters(query, revision):
            do {
                let result = try await placeRepository.fetchClusters(query: query)
                guard !Task.isCancelled else { return nil }
                return .clustersLoaded(result, revision: revision)
            } catch {
                guard !Task.isCancelled else { return nil }
                return .clusterLoadFailed(revision: revision)
            }
        }
    }

    func userHeadingUpdates() -> AsyncStream<Double> {
        locationService.headingUpdates()
    }
}

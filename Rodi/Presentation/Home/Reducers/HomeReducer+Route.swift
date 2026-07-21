//
//  HomeReducer+Route.swift
//  Rodi
//

import Foundation

extension HomeReducer {
    func reduceRouteAction(_ action: HomeAction.RouteAction, state: inout HomeState) -> Effect<HomeAction> {
        switch action {
        case .clearSelection:
            clearSelectionState(state: &state)
            return .cancel(id: HomeEffectID.routeLoading)

        case .selectItem(let item, let mediumHeight):
            state.bottomSheet.bottomSheetState = .medium
            state.bottomSheet.sheetHeight = mediumHeight
            return select(item, state: &state)

        case .selectMapMarker(let markerID, let mediumHeight):
            state.bottomSheet.bottomSheetState = .medium
            state.bottomSheet.sheetHeight = mediumHeight
            guard let item = state.visibleItems.first(where: {
                $0.mapMarker?.id == markerID
            }) else { break }
            return select(item, state: &state)

        case .detailLoaded(let detail):
            guard state.placeDetail.selectedPlaceID == detail.id else { return .none }

            let item = RodiCourseItem(placeDetail: detail)
            state.selection.selectedItem = item
            state.placeDetail.detail = detail
            state.placeDetail.isLoading = false
            state.placeDetail.isBookmarkUpdating = false
            return configureRoute(for: item, state: &state)

        case .detailAuthenticationRequired(let placeID):
            guard state.placeDetail.selectedPlaceID == placeID else { return .none }
            clearSelectionState(state: &state)
            state.presentation.authenticationRequestID += 1
            return .none

        case .detailFailed(let placeID, let message):
            guard state.placeDetail.selectedPlaceID == placeID else { return .none }
            clearSelectionState(state: &state)
            return snackbarEffect(message)

        case .toggleBookmark:
            guard let detail = state.placeDetail.detail,
                  !state.placeDetail.isBookmarkUpdating
            else {
                return .none
            }

            guard hasActiveSession() else {
                state.presentation.authenticationRequestID += 1
                return .none
            }

            let isBookmarked = !detail.isBookmarked
            state.placeDetail.detail = detail.updatingBookmark(isBookmarked: isBookmarked)
            state.placeDetail.isBookmarkUpdating = true
            return updateBookmarkEffect(
                placeID: detail.id,
                isBookmarked: isBookmarked,
                previousDetail: detail
            )

        case .bookmarkUpdated(let placeID, let isBookmarked):
            guard state.placeDetail.detail?.id == placeID else { return .none }
            state.placeDetail.detail = state.placeDetail.detail?.updatingBookmark(isBookmarked: isBookmarked)
            state.placeDetail.isBookmarkUpdating = false
            return snackbarEffect(isBookmarked ? "북마크를 저장했어요." : "북마크를 해제했어요.")

        case .bookmarkFailed(let placeID, let previousDetail, let message):
            guard state.placeDetail.detail?.id == placeID else { return .none }
            state.placeDetail.detail = previousDetail
            state.placeDetail.isBookmarkUpdating = false
            return snackbarEffect(message)

        case .roadRouteLoaded(let courseID, let path):
            guard state.selection.selectedItem?.id == courseID,
                  let selectedRouteOverlay = state.route.selectedRouteOverlay
            else { break }
            state.route.selectedRouteOverlay = RodiRouteOverlay(
                courseID: courseID,
                points: selectedRouteOverlay.points,
                path: path,
                isRoadRoute: true
            )
            state.route.isRouteLoading = false
            state.route.routeStatusMessage = nil

        case .roadRouteFailed(let courseID, let message):
            guard state.selection.selectedItem?.id == courseID else { break }
            state.route.isRouteLoading = false
            state.route.routeStatusMessage = message

        case .setSelectedRouteOverlay(let overlay):
            state.route.selectedRouteOverlay = overlay

        case .setRouteLoading(let isLoading):
            state.route.isRouteLoading = isLoading

        case .setRouteStatusMessage(let message):
            state.route.routeStatusMessage = message
        }

        return .none
    }

    func select(_ item: RodiCourseItem, state: inout HomeState) -> Effect<HomeAction> {
        state.selection.selectedItem = item
        state.route.routeStatusMessage = nil
        state.route.selectedRouteOverlay = nil
        state.route.isRouteLoading = false
        state.placeDetail.selectedPlaceID = item.id
        state.placeDetail.detail = nil
        state.placeDetail.isLoading = true
        state.placeDetail.isBookmarkUpdating = false

        return loadPlaceDetailEffect(placeID: item.id)
    }

    func configureRoute(for item: RodiCourseItem, state: inout HomeState) -> Effect<HomeAction> {
        state.route.routeStatusMessage = nil

        switch item.type {
        case .course:
            let points = item.routeOverlayPoints
            guard points.count >= 2 else {
                state.route.selectedRouteOverlay = nil
                state.route.routeStatusMessage = "경로 좌표가 아직 준비되지 않았어요."
                state.route.isRouteLoading = false
                return .cancel(id: HomeEffectID.routeLoading)
            }

            state.route.selectedRouteOverlay = RodiRouteOverlay(
                courseID: item.id,
                points: points,
                path: points.map(\.coordinate),
                isRoadRoute: false
            )
            state.route.isRouteLoading = true
            return loadRoadRouteEffect(courseID: item.id, points: points)

        case .single, .parking:
            state.route.selectedRouteOverlay = nil
            state.route.isRouteLoading = false
            state.map.cameraTarget = item.coordinate
            state.map.cameraFocus = .closeSingleLocation
            state.map.cameraRequestID += 1
            state.map.animatedCameraRequestID = state.map.cameraRequestID
            return .cancel(id: HomeEffectID.routeLoading)
        }
    }

    func clearSelectionState(state: inout HomeState) {
        state.selection.selectedItem = nil
        state.route.selectedRouteOverlay = nil
        state.route.isRouteLoading = false
        state.route.routeStatusMessage = nil
        state.placeDetail = HomePlaceDetailState()
    }

    func loadPlaceDetailEffect(placeID: Int) -> Effect<HomeAction> {
        let repository = placeRepository
        return .run { send in
            do {
                let detail = try await repository.fetchPlaceDetail(id: placeID)
                await send(.routeAction(.detailLoaded(detail)))
                RodiLogger.info("Home place detail loaded placeID=\(placeID), type=\(detail.type.rawValue)")
            } catch is CancellationError {
                RodiLogger.info("Home place detail request cancelled placeID=\(placeID)")
            } catch {
                RodiLogger.warning("Home place detail request failed placeID=\(placeID), error=\(error.localizedDescription)")
                if requiresAuthentication(error) {
                    await send(.routeAction(.detailAuthenticationRequired(placeID: placeID)))
                    return
                }
                await send(.routeAction(.detailFailed(
                    placeID: placeID,
                    message: "장소 상세 정보를 불러오지 못했어요."
                )))
            }
        }
        .cancelTask(id: HomeEffectID.placeDetailLoading)
    }

    func updateBookmarkEffect(
        placeID: Int,
        isBookmarked: Bool,
        previousDetail: PlaceDetail
    ) -> Effect<HomeAction> {
        let repository = placeRepository
        return .run { send in
            do {
                if isBookmarked {
                    try await repository.bookmark(placeID: placeID)
                } else {
                    try await repository.unbookmark(placeID: placeID)
                }
                await send(.routeAction(.bookmarkUpdated(placeID: placeID, isBookmarked: isBookmarked)))
                RodiLogger.info("Home bookmark updated placeID=\(placeID), isBookmarked=\(isBookmarked)")
            } catch is CancellationError {
                RodiLogger.info("Home bookmark request cancelled placeID=\(placeID)")
            } catch {
                RodiLogger.warning("Home bookmark update failed placeID=\(placeID), error=\(error.localizedDescription)")
                if requiresAuthentication(error) {
                    await send(.presentationAction(.requestAuthentication))
                    return
                }
                await send(.routeAction(.bookmarkFailed(
                    placeID: placeID,
                    previousDetail: previousDetail,
                    message: bookmarkFailureMessage(for: error, isBookmarked: isBookmarked)
                )))
            }
        }
        .cancelTask(id: HomeEffectID.bookmarkUpdating)
    }

    func bookmarkFailureMessage(for error: Error, isBookmarked: Bool) -> String {
        let action = isBookmarked ? "저장" : "해제"
        guard let networkError = error as? NetworkError else {
            return "북마크를 \(action)하지 못했어요."
        }

        switch networkError {
        case .networkUnavailable, .timeOut:
            return "인터넷 연결을 확인한 뒤 다시 시도해주세요."
        case .httpStatusCode(let statusCode) where statusCode >= 500:
            return "서버 오류로 북마크를 \(action)하지 못했어요."
        case .apiError(_, let message) where !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty:
            return message
        case .refreshFailGoRoot, .httpStatusCode(401):
            return "로그인이 만료됐어요. 다시 로그인해주세요."
        default:
            return "북마크를 \(action)하지 못했어요."
        }
    }

    func snackbarEffect(_ message: String) -> Effect<HomeAction> {
        .run { send in
            await send(.presentationAction(.showRouteGuidanceMessage(message)))
        }
    }

    func requiresAuthentication(_ error: Error) -> Bool {
        guard let networkError = error as? NetworkError else { return false }
        return switch networkError {
        case .refreshFailGoRoot, .httpStatusCode(401):
            true
        case .apiError(let code, _):
            code.hasPrefix("AUTH_401") || code == "AUTH_400_1"
        default:
            false
        }
    }

    func loadRoadRouteEffect(courseID: Int, points: [RodiRouteOverlayPoint]) -> Effect<HomeAction> {
        .run { send in
            do {
                let path = try await KakaoDirectionsService().fetchRoute(points: points)
                await send(.routeAction(.roadRouteLoaded(courseID: courseID, path: path)))
                RodiLogger.info("Road route loaded courseID=\(courseID), vertexCount=\(path.count)")
            } catch KakaoDirectionsError.missingAPIKey {
                await send(.routeAction(.roadRouteFailed(
                    courseID: courseID,
                    message: KakaoDirectionsError.missingAPIKey.fallbackMessage
                )))
                RodiLogger.warning("Kakao directions skipped: missing REST API key")
            } catch let error as KakaoDirectionsError {
                await send(.routeAction(.roadRouteFailed(
                    courseID: courseID,
                    message: error.fallbackMessage
                )))
                RodiLogger.warning("Kakao directions failed courseID=\(courseID), reason=\(error.logDescription)")
            } catch is CancellationError {
                RodiLogger.info("Kakao directions request cancelled courseID=\(courseID)")
            } catch {
                await send(.routeAction(.roadRouteFailed(
                    courseID: courseID,
                    message: "도로 경로를 불러오지 못해 대체 경로로 표시 중이에요."
                )))
                RodiLogger.warning("Kakao directions failed courseID=\(courseID), error=\(error.localizedDescription)")
            }
        }
        .cancelTask(id: HomeEffectID.routeLoading)
    }
}

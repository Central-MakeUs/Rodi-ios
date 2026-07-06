//
//  HomeReducer+Route.swift
//  Rodi
//

import Foundation

extension HomeReducer {
    func reduceRouteAction(_ action: HomeAction.RouteAction, state: inout HomeState) -> Effect<HomeAction> {
        switch action {
        case .clearSelection:
            state.selection.selectedItem = nil
            state.route.selectedRouteOverlay = nil
            state.route.isRouteLoading = false
            state.route.routeStatusMessage = nil
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

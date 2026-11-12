//
//  RodiKakaoMapView.swift
//  Rodi
//

import UIKit
import SwiftUI
import NSObject_Rx
import RxSwift
import SnapKit
import Then
import KakaoMapsSDK

final class RodiKakaoMapView: UIView {
    struct RenderInput: Equatable {
        let cameraTarget: RodiCoordinate
        let cameraRequestID: Int
        let animatedCameraRequestID: Int?
        let cameraFocus: RodiMapCameraFocus
        let userLocation: RodiCoordinate?
        let userHeadingDegrees: Double?
        let routeOverlay: RodiRouteOverlay?
        let mapMarkers: [RodiMapMarker]
        let logoBottomInset: CGFloat
        let cameraBottomInset: CGFloat
        let isInteractionEnabled: Bool
        let visibilityState: RodiMapVisibilityState
    }

    enum Constants {
        static let viewName = "rodi_home_map"
        static let mapLevel = 14
        static let koreaOverviewLevel = 6
        static let regionFocusLevel = 11
        static let regionFocusVerticalOffsetRatio: CGFloat = 0.05
        static let oneKilometerFocusLevel = 14
        static let closeSingleLocationLevel = 15
        static let courseMarkerFocusLevel = 16
        static let focusAnimationDurationMillis: UInt = 700
        static let userLocationLayerID = "rodi_user_location_layer"
        static let userDirectionLayerID = "rodi_user_direction_layer"
        static let userLocationPoiID = "rodi_user_location_poi"
        static let userDirectionFanPoiID = "rodi_user_direction_fan_poi"
        static let userLocationStyleID = "rodi_user_location_marker"
        static let userDirectionFanStyleID = "rodi_user_direction_fan_marker"
        static let userDirectionFanCanvasPadding: CGFloat = 8
        static let userDirectionFanOverlap: CGFloat = 2
        static let userLocationMarkerCanvasSize = CGSize(width: 30, height: 30)
        static let userLocationMarkerDiameter: CGFloat = 14
        static let userLocationMarkerBorderWidth: CGFloat = 2
        static let directionMarkerSize = CGSize(width: 8, height: 6)
        static let directionMarkerCanvasInset: CGFloat = 3
        static let routeMarkerLayerID = "rodi_route_marker_layer"
        static let routeShapeLayerID = "rodi_route_shape_layer"
        static let routePolylineShapeID = "rodi_route_polyline"
        static let routePolylineStyleID = "rodi_route_polyline_style"
        static let routeStartMarkerStyleID = "rodi_route_start_marker"
        static let routeWaypointMarkerStyleID = "rodi_route_waypoint_marker"
        static let routeEndMarkerStyleID = "rodi_route_end_marker"
        static let homeMarkerLayerID = "rodi_home_marker_layer"
        static let homeCourseMarkerStyleID = "rodi_home_course_marker"
        static let homeParkingInactiveMarkerStyleID = "rodi_home_parking_inactive_marker"
        static let homeParkingActiveMarkerStyleID = "rodi_home_parking_active_marker"
        static let parkingMarkerVisualHeight: CGFloat = 34
        static let duplicateMarkerLongitudeOffset = 0.00055
    }

    let mapContainer = KMViewContainer().then {
        $0.backgroundColor = .clear
    }

    weak var coordinator: KakaoMapContainerView.Coordinator?

    var mapController: KMController?
    var kakaoMap: KakaoMap?
    var latestCameraTarget = RodiCoordinate.seoulCityHall
    var latestUserLocation: RodiCoordinate?
    var latestUserHeadingDegrees: Double?
    var latestRouteOverlay: RodiRouteOverlay?
    var latestMapMarkers: [RodiMapMarker] = []
    var lastAppliedHomeMarkers: [RodiMapMarker] = []
    var latestLogoBottomInset: CGFloat = 0
    var lastAppliedLogoBottomInset: CGFloat?
    var latestCameraBottomInset: CGFloat = 0
    var lastAppliedMapInteractionEnabled: Bool?
    var latestVisibilityState: RodiMapVisibilityState = .interactive
    var lastAppliedRenderInput: RenderInput?
    var lastAppliedCameraRequestID: Int?
    var latestCameraRequestID = 0
    var latestAnimatedCameraRequestID: Int?
    var latestCameraFocus: RodiMapCameraFocus = .normal
    var userLocationLayer: LabelLayer?
    var userDirectionLayer: LabelLayer?
    var homeMarkerLayer: LabelLayer?
    var routeMarkerLayer: LabelLayer?
    var routeShapeLayer: ShapeLayer?
    var userLocationPoi: Poi?
    var userDirectionFanPoi: Poi?
    var renderedHomeMarkerIDs: Set<String> = []
    var homeMarkerIDsByPoiID: [String: String] = [:]
    var renderedHomeMarkersByPoiID: [String: RodiMapMarker] = [:]
    var renderedHomeMarkerCoordinatesByPoiID: [String: RodiCoordinate] = [:]
    var registeredHomeMarkerStyleIDs: Set<String> = []
    var routeMarkerPoiIDs: [String] = []
    var routePointIDsByPoiID: [String: Int] = [:]
    var mapEventHandlers: [DisposableEventHandler] = []
    var viewportChangeGeneration = 0
    var pendingProgrammaticViewportRequestID: Int?
    var programmaticViewportResetWorkItem: DispatchWorkItem?
    var didRegisterUserLocationStyle = false
    var didRegisterHomeMarkerStyles = false
    var didRegisterRouteStyles = false
    var didPrepareEngine = false
    var didActivateEngine = false
    var didCreateController = false
    var didPauseEngine = false
    var didFinalizeMapView = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    private func configureView() {
        RodiLogger.debug("RodiKakaoMapView init")
        backgroundColor = .systemBackground
        addSubview(mapContainer)
        mapContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        startEngineIfPossible(reason: "layoutSubviews")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        RodiLogger.debug("RodiKakaoMapView didMoveToWindow window=\(window != nil), bounds=\(bounds)")
        startEngineIfPossible(reason: "didMoveToWindow")
    }

    deinit {
        mapEventHandlers.removeAll()
        if didPrepareEngine {
            mapController?.pauseEngine()
            mapController?.resetEngine()
        }
    }

    func configure(
        cameraTarget: RodiCoordinate,
        cameraRequestID: Int,
        animatedCameraRequestID: Int?,
        cameraFocus: RodiMapCameraFocus,
        userLocation: RodiCoordinate?,
        userHeadingDegrees: Double?,
        routeOverlay: RodiRouteOverlay?,
        mapMarkers: [RodiMapMarker],
        logoBottomInset: CGFloat,
        cameraBottomInset: CGFloat,
        isInteractionEnabled: Bool,
        visibilityState: RodiMapVisibilityState,
        coordinator: KakaoMapContainerView.Coordinator
    ) {
        self.coordinator = coordinator
        latestCameraTarget = cameraTarget
        latestCameraRequestID = cameraRequestID
        latestAnimatedCameraRequestID = animatedCameraRequestID
        latestCameraFocus = cameraFocus
        latestUserLocation = userLocation
        latestUserHeadingDegrees = userHeadingDegrees
        latestRouteOverlay = routeOverlay
        latestMapMarkers = mapMarkers
        latestLogoBottomInset = logoBottomInset
        latestCameraBottomInset = cameraBottomInset
        latestVisibilityState = visibilityState
        RodiLogger.info(
            "Kakao map configure cameraTarget=\(RodiLogger.coordinate(cameraTarget)), userLocation=\(userLocation.logDescription), cameraRequestID=\(cameraRequestID), animatedCameraRequestID=\(animatedCameraRequestID.map(String.init) ?? "nil"), interaction=\(isInteractionEnabled), visibility=\(visibilityState)"
        )

        let controller = KMController(viewContainer: mapContainer)
        controller.delegate = coordinator
        coordinator.attach(mapView: self)
        mapController = controller
        didCreateController = true

        update(
            cameraTarget: cameraTarget,
            cameraRequestID: cameraRequestID,
            animatedCameraRequestID: animatedCameraRequestID,
            cameraFocus: cameraFocus,
            userLocation: userLocation,
            userHeadingDegrees: userHeadingDegrees,
            routeOverlay: routeOverlay,
            mapMarkers: mapMarkers,
            logoBottomInset: logoBottomInset,
            cameraBottomInset: cameraBottomInset,
            isInteractionEnabled: isInteractionEnabled,
            visibilityState: visibilityState
        )
        startEngineIfPossible(reason: "configure")
    }

    func update(
        cameraTarget: RodiCoordinate,
        cameraRequestID: Int,
        animatedCameraRequestID: Int?,
        cameraFocus: RodiMapCameraFocus,
        userLocation: RodiCoordinate?,
        userHeadingDegrees: Double?,
        routeOverlay: RodiRouteOverlay?,
        mapMarkers: [RodiMapMarker],
        logoBottomInset: CGFloat,
        cameraBottomInset: CGFloat,
        isInteractionEnabled: Bool,
        visibilityState: RodiMapVisibilityState
    ) {
        let renderInput = RenderInput(
            cameraTarget: cameraTarget,
            cameraRequestID: cameraRequestID,
            animatedCameraRequestID: animatedCameraRequestID,
            cameraFocus: cameraFocus,
            userLocation: userLocation,
            userHeadingDegrees: userHeadingDegrees,
            routeOverlay: routeOverlay,
            mapMarkers: mapMarkers,
            logoBottomInset: logoBottomInset,
            cameraBottomInset: cameraBottomInset,
            isInteractionEnabled: isInteractionEnabled,
            visibilityState: visibilityState
        )

        guard lastAppliedRenderInput != renderInput else { return }
        lastAppliedRenderInput = renderInput

        let previousUserLocation = latestUserLocation
        let previousHeadingDegrees = latestUserHeadingDegrees
        let didUserLocationChange = previousUserLocation != userLocation
        let didUserHeadingChange = previousHeadingDegrees != userHeadingDegrees
        latestCameraTarget = cameraTarget
        latestCameraRequestID = cameraRequestID
        latestAnimatedCameraRequestID = animatedCameraRequestID
        latestCameraFocus = cameraFocus
        latestUserLocation = userLocation
        latestUserHeadingDegrees = userHeadingDegrees
        let previousRouteOverlay = latestRouteOverlay
        latestRouteOverlay = routeOverlay
        latestMapMarkers = mapMarkers
        latestLogoBottomInset = logoBottomInset
        latestCameraBottomInset = cameraBottomInset
        latestVisibilityState = visibilityState

        let isMapActive = visibilityState.isActive
        let allowsMapInteraction = isMapActive && isInteractionEnabled
        isUserInteractionEnabled = allowsMapInteraction
        kakaoMap?.isEnabled = isMapActive
        applyGestureState(allowsMapInteraction)

        guard isMapActive else {
            pauseEngineIfNeeded(reason: "covered_update")
            return
        }

        startEngineIfPossible(reason: "active_update")
        activateEngineIfNeeded()
        updateLogoPosition()
        let needsUserLocationMarkerRecovery = userLocation != nil && userLocationPoi == nil
        if didUserLocationChange || didUserHeadingChange || needsUserLocationMarkerRecovery {
            updateUserLocationMarker(
                animatedHeading: shouldAnimateHeadingChange(
                    from: previousHeadingDegrees,
                    to: userHeadingDegrees
                )
            )
            recoverUserLocationMarkerIfNeeded()
        }
        updateHomeMarkers(with: mapMarkers)
        if previousRouteOverlay != routeOverlay {
            updateRouteOverlay()
        }

        if lastAppliedCameraRequestID != cameraRequestID {
            moveCamera(
                to: cameraTarget,
                requestID: cameraRequestID,
                animated: animatedCameraRequestID == cameraRequestID
            )
        }
    }

    func activateEngineIfNeeded() {
        guard latestVisibilityState.isActive else { return }
        guard didPrepareEngine else { return }
        guard !didActivateEngine || didPauseEngine else { return }
        mapController?.activateEngine()
        didActivateEngine = true
        didPauseEngine = false
    }

    func addMapView() {
        RodiLogger.info("Kakao map addViews requested")
        let point = MapPoint(longitude: latestCameraTarget.longitude, latitude: latestCameraTarget.latitude)
        let info = MapviewInfo(
            viewName: Constants.viewName,
            defaultPosition: point,
            defaultLevel: Constants.mapLevel
        )
        let viewSize = CGSize(
            width: max(mapContainer.bounds.width, bounds.width),
            height: max(mapContainer.bounds.height, bounds.height)
        )
        RodiLogger.info("Kakao map addView size=\(viewSize), containerBounds=\(mapContainer.bounds), bounds=\(bounds)")
        mapController?.addView(info, viewSize: viewSize)
    }

    func didAddMapView() {
        RodiLogger.info("Kakao map addView succeeded")
        guard let map = mapController?.getView(Constants.viewName) as? KakaoMap else {
            RodiLogger.error("Kakao map getView failed after addViewSucceeded")
            coordinator?.reportFailure("카카오맵을 불러오지 못했어요.")
            return
        }

        kakaoMap = map
        RodiLogger.info("Kakao map controller state after getView=\(mapStateDescription())")
        activateEngineIfNeeded()
        finalizeAddedMapViewWhenCreated(attempt: 0)
    }

    func finalizeAddedMapViewWhenCreated(attempt: Int) {
        guard let map = kakaoMap else { return }

        let stateDescription = mapStateDescription()
        if stateDescription.contains("State : not created"), attempt < 12 {
            RodiLogger.info("Kakao map waiting for render view creation attempt=\(attempt), state=\(stateDescription)")
            Observable<Int>
                .timer(.milliseconds(150), scheduler: MainScheduler.instance)
                .take(1)
                .subscribe(onNext: { [weak self] _ in
                    self?.activateEngineIfNeeded()
                    self?.finalizeAddedMapViewWhenCreated(attempt: attempt + 1)
                })
                .disposed(by: rx.disposeBag)
            return
        }

        guard !didFinalizeMapView else { return }
        didFinalizeMapView = true
        RodiLogger.info("Kakao map finalizing after render state attempt=\(attempt), state=\(stateDescription)")
        map.eventDelegate = coordinator
        registerMapEventHandlers(on: map)
        map.setPoiEnabled(true)
        map.poiClickable = true
        map.hideCompass()
        map.hideScaleBar()
        updateLogoPosition()
        applyGestureState(isUserInteractionEnabled)
        updateHomeMarkers(with: latestMapMarkers)
        updateRouteOverlay()

        guard latestVisibilityState.isActive else {
            pauseEngineIfNeeded(reason: "didAddMapView_covered")
            coordinator?.reportReady()
            return
        }

        activateEngineIfNeeded()
        updateUserLocationMarker(animatedHeading: false)
        recoverUserLocationMarkerIfNeeded()
        moveCamera(
            to: latestCameraTarget,
            requestID: latestCameraRequestID,
            animated: latestAnimatedCameraRequestID == latestCameraRequestID
        )
        RodiLogger.info(
            "Kakao map ready cameraTarget=\(RodiLogger.coordinate(latestCameraTarget)), userLocation=\(latestUserLocation.logDescription), level=\(Constants.mapLevel), cameraRequestID=\(latestCameraRequestID)"
        )
        completeInitialRenderAfterLayout()
    }

    func reportAuthenticationFailure(_ message: String) {
        RodiLogger.error("Kakao map authentication failure: \(message)")
        coordinator?.reportFailure(message)
    }

    func registerMapEventHandlers(on map: KakaoMap) {
        mapEventHandlers.removeAll()
        let cameraStoppedHandler = map.addCameraStoppedEventHandler(target: self) { target in
            { _ in
                target.reportCurrentViewport()
            }
        }
        mapEventHandlers.append(cameraStoppedHandler)
    }

    func reportCurrentViewport() {
        guard let map = kakaoMap else { return }
        let isProgrammaticMove = pendingProgrammaticViewportRequestID != nil
        pendingProgrammaticViewportRequestID = nil
        programmaticViewportResetWorkItem?.cancel()
        programmaticViewportResetWorkItem = nil
        let centerPoint = map.getPosition(CGPoint(x: bounds.midX, y: bounds.midY))
        let southWestPoint = map.getPosition(CGPoint(x: bounds.minX, y: bounds.maxY))
        let northEastPoint = map.getPosition(CGPoint(x: bounds.maxX, y: bounds.minY))
        let coordinate = RodiCoordinate(
            latitude: centerPoint.wgsCoord.latitude,
            longitude: centerPoint.wgsCoord.longitude
        )
        let viewport = PlaceViewport(
            southWestLatitude: southWestPoint.wgsCoord.latitude,
            southWestLongitude: southWestPoint.wgsCoord.longitude,
            northEastLatitude: northEastPoint.wgsCoord.latitude,
            northEastLongitude: northEastPoint.wgsCoord.longitude
        )
        viewportChangeGeneration += 1
        coordinator?.reportViewportChange(
            center: coordinate,
            zoomLevel: map.zoomLevel,
            viewport: viewport,
            isUserInitiated: !isProgrammaticMove
        )
    }

    func startEngineIfPossible(reason: String) {
        guard didCreateController else {
            RodiLogger.debug("Kakao map engine not ready to start: no controller, reason=\(reason)")
            return
        }

        guard !didPrepareEngine else { return }

        guard latestVisibilityState.isActive else {
            RodiLogger.debug("Kakao map engine start deferred while covered, reason=\(reason)")
            return
        }

        guard window != nil, !bounds.isEmpty else {
            RodiLogger.debug("Kakao map engine waiting for visible bounds, reason=\(reason), window=\(window != nil), bounds=\(bounds)")
            return
        }

        let prepared = mapController?.prepareEngine() ?? false
        didPrepareEngine = prepared
        RodiLogger.info("Kakao map prepareEngine result=\(prepared), reason=\(reason), bounds=\(bounds), state=\(mapStateDescription())")

        if !prepared {
            coordinator?.reportFailure("카카오맵 엔진을 준비하지 못했어요.")
        }
    }

    func pauseEngineIfNeeded(reason: String) {
        guard didPrepareEngine, !didPauseEngine else { return }
        mapController?.pauseEngine()
        didPauseEngine = true
        RodiLogger.info("Kakao map pauseEngine reason=\(reason)")
    }

    func mapStateDescription() -> String {
        mapController?.getStateDescMessage() ?? "nil"
    }

    func completeInitialRenderAfterLayout() {
        setNeedsLayout()
        layoutIfNeeded()

        let scheduledViewportGeneration = viewportChangeGeneration
        Observable<Int>
            .timer(.milliseconds(200), scheduler: MainScheduler.instance)
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                activateEngineIfNeeded()
                updateLogoPosition()
                updateUserLocationMarker(animatedHeading: false)
                updateHomeMarkers(with: latestMapMarkers)
                updateRouteOverlay()
                if scheduledViewportGeneration == viewportChangeGeneration {
                    moveCamera(
                        to: latestCameraTarget,
                        requestID: latestCameraRequestID,
                        animated: false
                    )
                    RodiLogger.info("Kakao map first render recovery applied requestID=\(latestCameraRequestID)")
                } else {
                    RodiLogger.info(
                        "Kakao map first render camera recovery skipped because viewport changed scheduledGeneration=\(scheduledViewportGeneration), currentGeneration=\(viewportChangeGeneration), requestID=\(latestCameraRequestID)"
                    )
                }
                coordinator?.reportReady()
                recoverFallbackTileRenderingIfNeeded()
            })
            .disposed(by: rx.disposeBag)
    }

    func recoverUserLocationMarkerIfNeeded() {
        guard latestUserLocation != nil,
              userLocationPoi == nil,
              latestVisibilityState.isActive
        else {
            return
        }

        Observable<Int>
            .timer(.milliseconds(450), scheduler: MainScheduler.instance)
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                guard let self,
                      latestUserLocation != nil,
                      userLocationPoi == nil,
                      latestVisibilityState.isActive
                else {
                    return
                }
                activateEngineIfNeeded()
                updateUserLocationMarker(animatedHeading: false)
            })
            .disposed(by: rx.disposeBag)
    }

    func recoverFallbackTileRenderingIfNeeded() {
        guard latestUserLocation == nil, latestVisibilityState.isActive else { return }

        let scheduledViewportGeneration = viewportChangeGeneration
        Observable<Int>
            .timer(.milliseconds(450), scheduler: MainScheduler.instance)
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                guard let self, latestUserLocation == nil, latestVisibilityState.isActive else { return }
                guard scheduledViewportGeneration == viewportChangeGeneration else {
                    RodiLogger.info(
                        "Kakao fallback tile render recovery skipped because viewport changed scheduledGeneration=\(scheduledViewportGeneration), currentGeneration=\(viewportChangeGeneration), requestID=\(latestCameraRequestID)"
                    )
                    return
                }
                mapContainer.setNeedsLayout()
                mapContainer.layoutIfNeeded()
                mapController?.pauseEngine()
                didPauseEngine = true
                activateEngineIfNeeded()
                updateLogoPosition()
                updateHomeMarkers(with: latestMapMarkers)
                moveCamera(
                    to: latestCameraTarget,
                    requestID: latestCameraRequestID,
                    animated: false
                )
                RodiLogger.info(
                    "Kakao fallback tile render recovery applied requestID=\(latestCameraRequestID), target=\(RodiLogger.coordinate(latestCameraTarget)), markerCount=\(latestMapMarkers.count), state=\(mapStateDescription())"
                )
            })
            .disposed(by: rx.disposeBag)
    }

    // MARK: - RodiMapCameraController

    func moveCamera(to coordinate: RodiCoordinate, requestID: Int, animated: Bool) {
        guard let map = kakaoMap else { return }
        lastAppliedCameraRequestID = requestID
        markProgrammaticViewportChange(requestID: requestID)

        if case let .cluster(coordinates) = latestCameraFocus {
            focusClusterArea(coordinates, requestID: requestID, animated: animated)
            return
        }

        let level = cameraLevel(for: map, animated: animated, focus: latestCameraFocus)
        let cameraTarget = adjustedCameraTarget(for: coordinate, level: level)
        RodiLogger.debug("Kakao map moveCamera requestID=\(requestID), center=\(RodiLogger.coordinate(cameraTarget)), original=\(RodiLogger.coordinate(coordinate)), level=\(level), currentLevel=\(map.zoomLevel), animated=\(animated), focus=\(latestCameraFocus), bottomInset=\(latestCameraBottomInset)")
        let point = MapPoint(longitude: cameraTarget.longitude, latitude: cameraTarget.latitude)
        let update = CameraUpdate.make(target: point, zoomLevel: level, mapView: map)

        if animated {
            let options = CameraAnimationOptions(
                autoElevation: true,
                consecutive: false,
                durationInMillis: Constants.focusAnimationDurationMillis
            )
            map.animateCamera(cameraUpdate: update, options: options) { [weak self] in
                self?.coordinator?.reportCameraMoveFinished(requestID)
            }
        } else {
            map.moveCamera(update) { [weak self] in
                self?.coordinator?.reportCameraMoveFinished(requestID)
            }
        }
    }

    /// 다음 cluster tier의 marker가 모두 보이도록 표시 영역을 맞춘다.
    func focusClusterArea(
        _ coordinates: [RodiCoordinate],
        requestID: Int,
        animated: Bool
    ) {
        guard let map = kakaoMap, !coordinates.isEmpty else { return }

        guard coordinates.count > 1 else {
            let coordinate = coordinates[0]
            let point = MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude)
            let level = min(max(Constants.oneKilometerFocusLevel, map.minLevel), map.maxLevel)
            let update = CameraUpdate.make(target: point, zoomLevel: level, mapView: map)
            applyClusterCamera(update, requestID: requestID, animated: animated)
            return
        }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        guard let minLatitude = latitudes.min(),
              let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(),
              let maxLongitude = longitudes.max()
        else {
            return
        }

        let latitudeSpan = max(maxLatitude - minLatitude, 0.008)
        let longitudeSpan = max(maxLongitude - minLongitude, 0.008)
        let bottomCoverageRatio = bounds.height > 0
            ? min(max(latestCameraBottomInset / bounds.height, 0), 0.7)
            : 0
        let bottomPadding = 0.25 + bottomCoverageRatio * 1.2
        let topPadding = 0.18
        let horizontalPadding = 0.2
        let area = AreaRect(points: [
            MapPoint(
                longitude: minLongitude - longitudeSpan * horizontalPadding,
                latitude: minLatitude - latitudeSpan * bottomPadding
            ),
            MapPoint(
                longitude: maxLongitude + longitudeSpan * horizontalPadding,
                latitude: maxLatitude + latitudeSpan * topPadding
            )
        ])
        applyClusterCamera(
            CameraUpdate.make(area: area, levelLimit: -1),
            requestID: requestID,
            animated: animated
        )
    }

    private func applyClusterCamera(
        _ update: CameraUpdate,
        requestID: Int,
        animated: Bool
    ) {
        if animated {
            let options = CameraAnimationOptions(
                autoElevation: true,
                consecutive: false,
                durationInMillis: Constants.focusAnimationDurationMillis
            )
            kakaoMap?.animateCamera(cameraUpdate: update, options: options) { [weak self] in
                self?.coordinator?.reportCameraMoveFinished(requestID)
            }
        } else {
            kakaoMap?.moveCamera(update) { [weak self] in
                self?.coordinator?.reportCameraMoveFinished(requestID)
            }
        }
    }

    private func markProgrammaticViewportChange(requestID: Int) {
        pendingProgrammaticViewportRequestID = requestID
        programmaticViewportResetWorkItem?.cancel()

        let resetWorkItem = DispatchWorkItem { [weak self] in
            guard self?.pendingProgrammaticViewportRequestID == requestID else { return }
            self?.pendingProgrammaticViewportRequestID = nil
        }
        programmaticViewportResetWorkItem = resetWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: resetWorkItem)
    }

    func adjustedCameraTarget(for coordinate: RodiCoordinate, level: Int) -> RodiCoordinate {
        if latestCameraFocus == .region {
            let markerYOffset = bounds.height * Constants.regionFocusVerticalOffsetRatio
            let metersPerPixel = metersPerPixel(latitude: coordinate.latitude, zoomLevel: level)
            let latitudeOffset = metersToLatitudeDegrees(markerYOffset * metersPerPixel)
            return RodiCoordinate(
                latitude: coordinate.latitude - latitudeOffset,
                longitude: coordinate.longitude
            )
        }

        guard (
            latestCameraFocus == .closeSingleLocation ||
            latestCameraFocus == .courseMarker ||
            latestCameraFocus == .currentLocation
        ),
              latestCameraBottomInset > 0,
              bounds.height > latestCameraBottomInset
        else {
            return coordinate
        }

        let markerYOffset = max((latestCameraBottomInset / 2) - selectedMarkerVisualCenterOffset(for: latestCameraFocus), 0)
        let metersPerPixel = metersPerPixel(latitude: coordinate.latitude, zoomLevel: level)
        let latitudeOffset = metersToLatitudeDegrees(markerYOffset * metersPerPixel)

        return RodiCoordinate(
            latitude: coordinate.latitude - latitudeOffset,
            longitude: coordinate.longitude
        )
    }

    func selectedMarkerVisualCenterOffset(for focus: RodiMapCameraFocus) -> CGFloat {
        guard focus == .closeSingleLocation,
              latestMapMarkers.count == 1,
              latestMapMarkers[0].kind == .parking
        else {
            return 0
        }

        return Constants.parkingMarkerVisualHeight / 2
    }

    func metersPerPixel(latitude: Double, zoomLevel: Int) -> Double {
        let earthCircumferenceMeters = 156_543.03392
        return earthCircumferenceMeters * cos(latitude * .pi / 180) / pow(2, Double(zoomLevel))
    }

    func metersToLatitudeDegrees(_ meters: Double) -> Double {
        meters / 111_320
    }

    func cameraLevel(for map: KakaoMap, animated: Bool, focus: RodiMapCameraFocus) -> Int {
        if focus == .koreaOverview {
            return min(max(Constants.koreaOverviewLevel, map.minLevel), map.maxLevel)
        }

        if focus == .region {
            return min(max(Constants.regionFocusLevel, map.minLevel), map.maxLevel)
        }

        if focus == .closeSingleLocation {
            return min(max(Constants.closeSingleLocationLevel, map.minLevel), map.maxLevel)
        }

        if focus == .courseMarker {
            return min(max(Constants.courseMarkerFocusLevel, map.minLevel), map.maxLevel)
        }

        guard animated else { return Constants.mapLevel }

        let currentLevel = map.zoomLevel
        let oneKilometerLevel = min(Constants.oneKilometerFocusLevel, map.maxLevel)
        let targetLevel = max(currentLevel, oneKilometerLevel)
        return min(max(targetLevel, map.minLevel), map.maxLevel)
    }

    // MARK: - RodiMapHomeMarkerStyles

    func registerHomeMarkerStylesIfNeeded(with manager: LabelManager) {
        guard !didRegisterHomeMarkerStyles else { return }

        manager.addPoiStyle(
            makeImageMarkerStyle(
                styleID: Constants.homeParkingInactiveMarkerStyleID,
                assetName: "ic_parking_inactive",
                fallbackImage: makeFallbackParkingMarkerImage(),
                anchorPoint: CGPoint(x: 0.5, y: 1.0)
            )
        )
        registeredHomeMarkerStyleIDs.insert(Constants.homeParkingInactiveMarkerStyleID)

        manager.addPoiStyle(
            makeImageMarkerStyle(
                styleID: Constants.homeParkingActiveMarkerStyleID,
                assetName: "ic_parking_active",
                fallbackImage: makeFallbackParkingMarkerImage(),
                anchorPoint: CGPoint(x: 0.5, y: 1.0)
            )
        )
        registeredHomeMarkerStyleIDs.insert(Constants.homeParkingActiveMarkerStyleID)

        didRegisterHomeMarkerStyles = true
    }

    func registerHomeMarkerStyleIfNeeded(for marker: RodiMapMarker, styleID: String, with manager: LabelManager) {
        guard !registeredHomeMarkerStyleIDs.contains(styleID) else { return }

        switch marker.kind {
        case .course:
            manager.addPoiStyle(
                makeCourseLabelMarkerStyle(styleID: styleID, title: marker.title)
            )
        case .parking:
            break
        case .cluster:
            manager.addPoiStyle(
                makeClusterCountMarkerStyle(styleID: styleID, countText: marker.title)
            )
        }

        registeredHomeMarkerStyleIDs.insert(styleID)
    }

    func makeImageMarkerStyle(
        styleID: String,
        assetName: String,
        fallbackImage: UIImage,
        anchorPoint: CGPoint
    ) -> PoiStyle {
        let iconStyle = PoiIconStyle(
            symbol: UIImage(named: assetName) ?? fallbackImage,
            anchorPoint: anchorPoint
        )
        return PoiStyle(styleID: styleID, styles: [PerLevelPoiStyle(iconStyle: iconStyle, level: 0)])
    }

    func makeCourseLabelMarkerStyle(styleID: String, title: String) -> PoiStyle {
        let iconStyle = PoiIconStyle(
            symbol: makeCourseLabelMarkerImage(title: title),
            anchorPoint: CGPoint(x: 0.5, y: 0.5)
        )
        return PoiStyle(styleID: styleID, styles: [PerLevelPoiStyle(iconStyle: iconStyle, level: 0)])
    }

    func makeCourseLabelMarkerImage(title: String) -> UIImage {
        let displayTitle = String(title.prefix(12))
        let font = UIFont.pretendard(size: 10, weight: .medium)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        let textSize = (displayTitle as NSString).size(withAttributes: textAttributes)
        let horizontalPadding: CGFloat = 9
        let verticalPadding: CGFloat = 3
        let shadowPadding: CGFloat = 6
        let markerSize = CGSize(
            width: ceil(textSize.width + horizontalPadding * 2),
            height: ceil(textSize.height + verticalPadding * 2)
        )
        let canvasSize = CGSize(
            width: markerSize.width + shadowPadding * 2,
            height: markerSize.height + shadowPadding * 2
        )
        let renderer = UIGraphicsImageRenderer(size: canvasSize)

        return renderer.image { context in
            let markerRect = CGRect(
                x: shadowPadding,
                y: shadowPadding,
                width: markerSize.width,
                height: markerSize.height
            )
            let path = UIBezierPath(roundedRect: markerRect, cornerRadius: 14)

            context.cgContext.setShadow(
                offset: CGSize(width: 0, height: 3),
                blur: 6,
                color: UIColor.black.withAlphaComponent(0.18).cgColor
            )
            UIColor(red: 0.439, green: 0.384, blue: 1.0, alpha: 1.0).setFill()
            path.fill()
            context.cgContext.setShadow(offset: .zero, blur: 0, color: nil)

            let textRect = CGRect(
                x: markerRect.minX + horizontalPadding,
                y: markerRect.minY + verticalPadding,
                width: textSize.width,
                height: textSize.height
            )
            (displayTitle as NSString).draw(in: textRect, withAttributes: textAttributes)
        }
    }

    func makeClusterCountMarkerStyle(styleID: String, countText: String) -> PoiStyle {
        let iconStyle = PoiIconStyle(
            symbol: makeClusterCountMarkerImage(countText: countText),
            anchorPoint: CGPoint(x: 0.5, y: 1.0)
        )
        return PoiStyle(styleID: styleID, styles: [PerLevelPoiStyle(iconStyle: iconStyle, level: 0)])
    }

    func makeClusterCountMarkerImage(countText: String) -> UIImage {
        RodiClusterCountMarkerView(countText: countText).renderedImage()
    }

    func makeFallbackParkingMarkerImage() -> UIImage {
        let size = CGSize(width: 24, height: 30)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let circleRect = CGRect(x: 3, y: 1, width: 18, height: 18)

            UIColor.black.withAlphaComponent(0.16).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 5, y: 24, width: 14, height: 4))

            UIColor(red: 0.19, green: 0.43, blue: 1.0, alpha: 1.0).setFill()
            context.cgContext.fillEllipse(in: circleRect)

            let tailPath = UIBezierPath()
            tailPath.move(to: CGPoint(x: size.width / 2, y: size.height - 2))
            tailPath.addLine(to: CGPoint(x: 7, y: 15))
            tailPath.addLine(to: CGPoint(x: 17, y: 15))
            tailPath.close()
            tailPath.fill()

            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: circleRect.insetBy(dx: 6, dy: 6))
        }
    }

    // MARK: - RodiMapHomeMarkers

    func updateHomeMarkers(with markers: [RodiMapMarker]) {
        guard let map = kakaoMap else { return }
        guard lastAppliedHomeMarkers != markers else { return }

        let manager = map.getLabelManager()
        registerHomeMarkerStylesIfNeeded(with: manager)

        if homeMarkerLayer == nil {
            let options = LabelLayerOptions(
                layerID: Constants.homeMarkerLayerID,
                competitionType: .none,
                competitionUnit: .poi,
                orderType: .rank,
                zOrder: 7_000
            )
            homeMarkerLayer = manager.addLabelLayer(option: options)
            homeMarkerLayer?.setClickable(true)
        }

        let desiredMarkersByPoiID = Dictionary(
            uniqueKeysWithValues: markers.map { (homeMarkerPoiID(for: $0), $0) }
        )
        let desiredCoordinatesByPoiID = Dictionary(
            uniqueKeysWithValues: markers.map {
                (homeMarkerPoiID(for: $0), displayCoordinate(for: $0, in: markers))
            }
        )
        let currentIDs = Set(renderedHomeMarkersByPoiID.keys)
        let desiredIDs = Set(desiredMarkersByPoiID.keys)

        let updatedIDs = currentIDs.intersection(desiredIDs).filter { poiID in
            renderedHomeMarkersByPoiID[poiID] != desiredMarkersByPoiID[poiID]
                || renderedHomeMarkerCoordinatesByPoiID[poiID] != desiredCoordinatesByPoiID[poiID]
        }
        let addedIDs = desiredIDs.subtracting(currentIDs)

        // Add new POIs before removing obsolete ones so zoom tier transitions never show a blank map.
        addedIDs.sorted().forEach { poiID in
            guard let marker = desiredMarkersByPoiID[poiID],
                  let coordinate = desiredCoordinatesByPoiID[poiID]
            else { return }
            addHomeMarker(marker, poiID: poiID, coordinate: coordinate, manager: manager)
        }

        updatedIDs.sorted().forEach { poiID in
            guard let marker = desiredMarkersByPoiID[poiID],
                  let coordinate = desiredCoordinatesByPoiID[poiID]
            else { return }
            updateHomeMarker(marker, poiID: poiID, coordinate: coordinate, manager: manager)
        }

        currentIDs.subtracting(desiredIDs).forEach { poiID in
            homeMarkerLayer?.removePoi(poiID: poiID)
            renderedHomeMarkerIDs.remove(poiID)
            homeMarkerIDsByPoiID.removeValue(forKey: poiID)
            renderedHomeMarkersByPoiID.removeValue(forKey: poiID)
            renderedHomeMarkerCoordinatesByPoiID.removeValue(forKey: poiID)
        }

        lastAppliedHomeMarkers = markers
    }

    func addHomeMarker(
        _ marker: RodiMapMarker,
        poiID: String,
        coordinate: RodiCoordinate,
        manager: LabelManager
    ) {
        let styleID = homeMarkerStyleID(for: marker)
        registerHomeMarkerStyleIfNeeded(for: marker, styleID: styleID, with: manager)

        let options = PoiOptions(styleID: styleID, poiID: poiID)
        options.rank = homeMarkerRank(for: marker.kind)
        options.transformType = .decal
        let point = MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude)

        if let poi = homeMarkerLayer?.addPoi(option: options, at: point) {
            poi.clickable = true
            poi.show()
            renderedHomeMarkerIDs.insert(poiID)
            homeMarkerIDsByPoiID[poiID] = marker.id
            renderedHomeMarkersByPoiID[poiID] = marker
            renderedHomeMarkerCoordinatesByPoiID[poiID] = coordinate
        }
    }

    func updateHomeMarker(
        _ marker: RodiMapMarker,
        poiID: String,
        coordinate: RodiCoordinate,
        manager: LabelManager
    ) {
        guard let poi = homeMarkerLayer?.getPoi(poiID: poiID) else {
            addHomeMarker(marker, poiID: poiID, coordinate: coordinate, manager: manager)
            return
        }

        let styleID = homeMarkerStyleID(for: marker)
        registerHomeMarkerStyleIfNeeded(for: marker, styleID: styleID, with: manager)
        poi.changeStyle(styleID: styleID)
        poi.moveAt(MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude), duration: 0)
        poi.clickable = true
        renderedHomeMarkersByPoiID[poiID] = marker
        renderedHomeMarkerCoordinatesByPoiID[poiID] = coordinate
        homeMarkerIDsByPoiID[poiID] = marker.id
    }

    func homeMarkerRank(for kind: RodiMapMarkerKind) -> Int {
        switch kind {
        case .parking: 1
        case .course: 2
        case .cluster: 3
        }
    }

    func displayCoordinate(for marker: RodiMapMarker, in markers: [RodiMapMarker]) -> RodiCoordinate {
        let duplicateMarkers = markers.filter {
            coordinateKey(for: $0.coordinate) == coordinateKey(for: marker.coordinate)
        }
        guard duplicateMarkers.count > 1,
              let duplicateIndex = duplicateMarkers.firstIndex(where: { $0.id == marker.id })
        else {
            return marker.coordinate
        }

        let middleIndex = Double(duplicateMarkers.count - 1) / 2
        let offsetIndex = Double(duplicateIndex) - middleIndex
        let longitudeOffset = offsetIndex * Constants.duplicateMarkerLongitudeOffset
        return RodiCoordinate(
            latitude: marker.coordinate.latitude,
            longitude: marker.coordinate.longitude + longitudeOffset
        )
    }

    func coordinateKey(for coordinate: RodiCoordinate) -> String {
        "\(String(format: "%.6f", coordinate.latitude)):\(String(format: "%.6f", coordinate.longitude))"
    }

    func handleHomeMarkerTap(layerID: String, poiID: String) {
        guard layerID == Constants.homeMarkerLayerID else { return }
        guard let markerID = homeMarkerIDsByPoiID[poiID] else {
            RodiLogger.warning("Kakao home marker tap ignored: missing marker id poiID=\(poiID)")
            return
        }

        RodiLogger.info("Kakao home marker tapped markerID=\(markerID), poiID=\(poiID)")
        coordinator?.reportMarkerTap(markerID)
    }

    func homeMarkerStyleID(for marker: RodiMapMarker) -> String {
        switch marker.kind {
        case .course:
            "\(Constants.homeCourseMarkerStyleID)_\(stableStyleIdentifier(for: "\(marker.id):\(marker.title)"))"
        case .parking:
            marker.isSelected
                ? Constants.homeParkingActiveMarkerStyleID
                : Constants.homeParkingInactiveMarkerStyleID
        case .cluster:
            "rodi_home_cluster_\(stableStyleIdentifier(for: "\(marker.id):\(marker.title)"))"
        }
    }

    /// Kakao POI style ID는 ASCII로 고정해 주소에 포함된 한글/공백과 무관하게 재사용한다.
    func stableStyleIdentifier(for value: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }

    func homeMarkerPoiID(for marker: RodiMapMarker) -> String {
        "rodi_home_\(marker.id.replacingOccurrences(of: "-", with: "_"))"
    }

    // MARK: - RodiMapRouteOverlay

    func updateRouteOverlay() {
        guard let map = kakaoMap else { return }

        clearRouteOverlay()

        guard let routeOverlay = latestRouteOverlay else { return }

        let labelManager = map.getLabelManager()
        let shapeManager = map.getShapeManager()
        registerRouteStylesIfNeeded(labelManager: labelManager, shapeManager: shapeManager)

        if routeMarkerLayer == nil {
            let options = LabelLayerOptions(
                layerID: Constants.routeMarkerLayerID,
                competitionType: .none,
                competitionUnit: .poi,
                orderType: .rank,
                zOrder: 9_000
            )
            routeMarkerLayer = labelManager.addLabelLayer(option: options)
            routeMarkerLayer?.setClickable(true)
        }

        if routeShapeLayer == nil {
            routeShapeLayer = shapeManager.addShapeLayer(layerID: Constants.routeShapeLayerID, zOrder: 8_500)
        }

        routeOverlay.points.forEach { point in
            let poiID = "rodi_route_marker_\(routeOverlay.courseID)_\(point.id)"
            let options = PoiOptions(styleID: markerStyleID(for: point.role), poiID: poiID)
            options.rank = 1
            options.transformType = .decal
            let mapPoint = MapPoint(
                longitude: point.coordinate.longitude,
                latitude: point.coordinate.latitude
            )

            if let poi = routeMarkerLayer?.addPoi(option: options, at: mapPoint) {
                poi.clickable = true
                poi.show()
                routeMarkerPoiIDs.append(poiID)
                routePointIDsByPoiID[poiID] = point.id
            }
        }

        let pathPoints = routeOverlay.path.map {
            MapPoint(longitude: $0.longitude, latitude: $0.latitude)
        }
        if pathPoints.count >= 2 {
            let options = MapPolylineShapeOptions(
                shapeID: Constants.routePolylineShapeID,
                styleID: Constants.routePolylineStyleID,
                zOrder: 0
            )
            options.polylines = [MapPolyline(line: pathPoints, styleIndex: 0)]
            routeShapeLayer?.addMapPolylineShape(options)?.show()
            focusRouteArea(routeOverlay.path)
        }

        RodiLogger.info(
            "Kakao route overlay rendered courseID=\(routeOverlay.courseID), markerCount=\(routeOverlay.points.count), pathCount=\(routeOverlay.path.count), isRoadRoute=\(routeOverlay.isRoadRoute)"
        )
    }

    func clearRouteOverlay() {
        routeMarkerPoiIDs.forEach {
            routeMarkerLayer?.removePoi(poiID: $0)
        }
        routeMarkerPoiIDs.removeAll()
        routePointIDsByPoiID.removeAll()
        routeShapeLayer?.removeMapPolylineShape(shapeID: Constants.routePolylineShapeID)
    }

    func handlePoiTap(layerID: String, poiID: String) {
        if layerID == Constants.routeMarkerLayerID,
           let pointID = routePointIDsByPoiID[poiID] {
            coordinator?.reportRoutePointTap(pointID)
            return
        }
        handleHomeMarkerTap(layerID: layerID, poiID: poiID)
    }

    func focusRouteArea(_ coordinates: [RodiCoordinate]) {
        guard let map = kakaoMap, coordinates.count >= 2 else { return }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        guard
            let minLatitude = latitudes.min(),
            let maxLatitude = latitudes.max(),
            let minLongitude = longitudes.min(),
            let maxLongitude = longitudes.max()
        else {
            return
        }

        let latitudeSpan = max(maxLatitude - minLatitude, 0.016)
        let longitudeSpan = max(maxLongitude - minLongitude, 0.016)
        let bottomCoverageRatio = bounds.height > 0
            ? min(max(latestCameraBottomInset / bounds.height, 0), 0.7)
            : 0.4
        // 경로의 전체 모양은 보존하되, 이전의 과도한 기본 여백을 줄여
        // marker 탭 직후 polyline이 사용 가능한 지도 영역을 더 크게 채우게 합니다.
        let bottomLatitudePadding = 0.28 + bottomCoverageRatio * 1.15
        let topLatitudePadding = 0.20
        let paddedMinLatitude = minLatitude - latitudeSpan * bottomLatitudePadding
        let paddedMaxLatitude = maxLatitude + latitudeSpan * topLatitudePadding
        let paddedMinLongitude = minLongitude - longitudeSpan * 0.20
        let paddedMaxLongitude = maxLongitude + longitudeSpan * 0.20
        let paddedPoints = [
            MapPoint(longitude: paddedMinLongitude, latitude: paddedMinLatitude),
            MapPoint(longitude: paddedMaxLongitude, latitude: paddedMinLatitude),
            MapPoint(longitude: paddedMinLongitude, latitude: paddedMaxLatitude),
            MapPoint(longitude: paddedMaxLongitude, latitude: paddedMaxLatitude)
        ]
        let area = AreaRect(points: paddedPoints)
        let update = CameraUpdate.make(area: area, levelLimit: -1)
        let options = CameraAnimationOptions(
            autoElevation: true,
            consecutive: false,
            durationInMillis: Constants.focusAnimationDurationMillis
        )
        map.animateCamera(cameraUpdate: update, options: options)
        RodiLogger.info(
            "Kakao route camera focused with bottom-sheet padding latSpan=\(latitudeSpan), lngSpan=\(longitudeSpan), bottomRatio=\(bottomCoverageRatio), bottomPadding=\(bottomLatitudePadding), points=\(coordinates.count)"
        )
    }


    // MARK: - RodiMapRouteStyles

    private enum RouteMarkerLayout {
        static let size = CGSize(width: 66, height: 66)
        // SVG의 실제 핀 꼭지점은 캔버스 맨 아래보다 1.5pt 위에 있다.
        // 꼭지점이 좌표에 정확히 닿도록 anchor를 그 위치에 맞춘다.
        static let tipAnchorPoint = CGPoint(x: 0.5, y: 32.5 / 34)
    }

    func registerRouteStylesIfNeeded(labelManager: LabelManager, shapeManager: ShapeManager) {
        guard !didRegisterRouteStyles else { return }

        labelManager.addPoiStyle(makeRouteMarkerStyle(styleID: Constants.routeStartMarkerStyleID, assetName: "ic_start_pin"))
        labelManager.addPoiStyle(makeRouteWaypointMarkerStyle())
        labelManager.addPoiStyle(makeRouteMarkerStyle(styleID: Constants.routeEndMarkerStyleID, assetName: "ic_arrival_pin"))

        let lineStyle = PerLevelPolylineStyle(
            bodyColor: UIColor(red: 0.337, green: 0.251, blue: 1.0, alpha: 1.0),
            bodyWidth: 12,
            strokeColor: UIColor(RodiColor.primary800),
            strokeWidth: 2,
            level: 0
        )
        let style = PolylineStyle(styles: [lineStyle])
        let styleSet = PolylineStyleSet(styleSetID: Constants.routePolylineStyleID, styles: [style], capType: .round)
        shapeManager.addPolylineStyleSet(styleSet)

        didRegisterRouteStyles = true
    }

    func makeRouteMarkerStyle(styleID: String, assetName: String) -> PoiStyle {
        let image = routeMarkerImage(assetName: assetName)
        let iconStyle = PoiIconStyle(symbol: image, anchorPoint: RouteMarkerLayout.tipAnchorPoint)
        return PoiStyle(
            styleID: styleID,
            styles: [PerLevelPoiStyle(iconStyle: iconStyle, level: 0)]
        )
    }

    func makeRouteWaypointMarkerStyle() -> PoiStyle {
        let image = routeMarkerImage(assetName: "ic_route_waypoint")
        let iconStyle = PoiIconStyle(symbol: image, anchorPoint: RouteMarkerLayout.tipAnchorPoint)
        return PoiStyle(
            styleID: Constants.routeWaypointMarkerStyleID,
            styles: [PerLevelPoiStyle(iconStyle: iconStyle, level: 0)]
        )
    }

    func markerStyleID(for role: RodiCoursePointRole) -> String {
        switch role {
        case .start:
            Constants.routeStartMarkerStyleID
        case .waypoint:
            Constants.routeWaypointMarkerStyleID
        case .end:
            Constants.routeEndMarkerStyleID
        }
    }

    func makeFallbackRouteMarkerImage() -> UIImage {
        let size = RouteMarkerLayout.size
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let pinRect = CGRect(x: 4, y: 2, width: 26, height: 26)
            UIColor(red: 0.337, green: 0.251, blue: 1.0, alpha: 1.0).setFill()
            context.cgContext.fillEllipse(in: pinRect)

            let path = UIBezierPath()
            path.move(to: CGPoint(x: size.width / 2, y: size.height - 2))
            path.addLine(to: CGPoint(x: 9, y: 22))
            path.addLine(to: CGPoint(x: 25, y: 22))
            path.close()
            path.fill()

            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: pinRect.insetBy(dx: 8, dy: 8))
        }
    }

    func routeMarkerImage(assetName: String) -> UIImage {
        guard let asset = UIImage(named: assetName) else {
            return makeFallbackRouteMarkerImage()
        }

        let format = UIGraphicsImageRendererFormat.default()
        // Kakao 지도 SDK는 이미지의 실제 픽셀 크기로 POI를 표시하므로, 중앙 고정 핀과 균형이 맞는 크기로 정규화한다.
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: RouteMarkerLayout.size, format: format)
        return renderer.image { _ in
            asset.draw(in: CGRect(origin: .zero, size: RouteMarkerLayout.size))
        }
    }

    // MARK: - RodiMapViewChrome

    func updateLogoPosition() {
        guard let map = kakaoMap else { return }
        let inset = max(12, latestLogoBottomInset)
        guard lastAppliedLogoBottomInset != inset else { return }
        let origin = GuiAlignment(vAlign: .bottom, hAlign: .left)
        map.setLogoPosition(origin: origin, position: CGPoint(x: 16, y: -inset))
        lastAppliedLogoBottomInset = inset
    }

    func applyGestureState(_ isEnabled: Bool) {
        guard let map = kakaoMap else { return }
        guard lastAppliedMapInteractionEnabled != isEnabled else { return }
        map.setGestureEnable(type: .pan, enable: isEnabled)
        map.setGestureEnable(type: .zoom, enable: isEnabled)
        map.setGestureEnable(type: .rotate, enable: isEnabled)
        map.setGestureEnable(type: .tilt, enable: isEnabled)
        map.setGestureEnable(type: .doubleTapZoomIn, enable: isEnabled)
        map.setGestureEnable(type: .twoFingerTapZoomOut, enable: isEnabled)
        map.setGestureEnable(type: .longTapAndDrag, enable: isEnabled)
        map.setGestureEnable(type: .rotateZoom, enable: isEnabled)
        map.setGestureEnable(type: .oneFingerZoom, enable: isEnabled)
        lastAppliedMapInteractionEnabled = isEnabled
    }


    // MARK: - RodiUserLocationMarker

    func updateUserLocationMarker(animatedHeading: Bool) {
        guard let map = kakaoMap else { return }

        guard let coordinate = latestUserLocation else {
            removeUserLocationMarker()
            return
        }

        let point = MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude)
        if let userLocationPoi {
            userLocationPoi.moveAt(point, duration: 0)
            userDirectionFanPoi?.moveAt(point, duration: 0)
            updateUserDirectionMarkerOrientation(animated: animatedHeading)
            RodiLogger.debug("Kakao user location marker moved coordinate=\(RodiLogger.coordinate(coordinate))")
            return
        }

        let manager = map.getLabelManager()
        registerUserLocationStyleIfNeeded(with: manager)

        if userLocationLayer == nil {
            let options = LabelLayerOptions(
                layerID: Constants.userLocationLayerID,
                competitionType: .none,
                competitionUnit: .poi,
                orderType: .rank,
                zOrder: 10_000
            )
            userLocationLayer = manager.addLabelLayer(option: options)
        }

        if userDirectionLayer == nil {
            let options = LabelLayerOptions(
                layerID: Constants.userDirectionLayerID,
                competitionType: .none,
                competitionUnit: .poi,
                orderType: .rank,
                zOrder: 9_999
            )
            userDirectionLayer = manager.addLabelLayer(option: options)
        }

        guard let locationLayer = userLocationLayer, let directionLayer = userDirectionLayer else {
            RodiLogger.warning("Kakao user location layer creation failed")
            return
        }

        let locationOptions = PoiOptions(
            styleID: Constants.userLocationStyleID,
            poiID: Constants.userLocationPoiID
        )
        locationOptions.rank = 1
        locationOptions.transformType = .decal

        guard let locationPoi = locationLayer.addPoi(option: locationOptions, at: point) else {
            RodiLogger.warning("Kakao user location marker unavailable")
            return
        }

        let fanOptions = PoiOptions(
            styleID: Constants.userDirectionFanStyleID,
            poiID: Constants.userDirectionFanPoiID
        )
        fanOptions.rank = 2
        fanOptions.transformType = .absoluteRotationDecal

        let fanPoi = directionLayer.addPoi(option: fanOptions, at: point)
        if fanPoi == nil {
            RodiLogger.warning("Kakao user direction fan marker unavailable")
        }

        userLocationPoi = locationPoi
        userDirectionFanPoi = fanPoi

        if let fanPoi {
            fanPoi.show()
        }
        updateUserDirectionMarkerOrientation(animated: false)
        locationPoi.show()
        RodiLogger.info("Kakao user location marker shown coordinate=\(RodiLogger.coordinate(coordinate))")
    }

    func shouldAnimateHeadingChange(from previousHeading: Double?, to nextHeading: Double?) -> Bool {
        guard let previousHeading, let nextHeading else { return false }
        let rawDifference = abs(previousHeading - nextHeading).truncatingRemainder(dividingBy: 360)
        let shortestDifference = min(rawDifference, 360 - rawDifference)
        return shortestDifference >= 0.5
    }

    func removeUserLocationMarker() {
        var didRemoveMarker = false
        if userLocationPoi != nil {
            userLocationLayer?.removePoi(poiID: Constants.userLocationPoiID)
            userLocationPoi = nil
            didRemoveMarker = true
        }
        if userDirectionFanPoi != nil {
            userDirectionLayer?.removePoi(poiID: Constants.userDirectionFanPoiID)
            userDirectionFanPoi = nil
            didRemoveMarker = true
        }
        if didRemoveMarker {
            RodiLogger.debug("Kakao user location marker removed")
        }
    }

    func updateUserDirectionMarkerOrientation(animated: Bool) {
        guard let heading = latestUserHeadingDegrees, let userDirectionFanPoi else { return }
        let radians = heading * .pi / 180
        if animated {
            userDirectionFanPoi.rotateAt(radians, duration: 180)
        } else {
            userDirectionFanPoi.orientation = radians
        }
        RodiLogger.debug("Kakao user direction marker heading=\(heading), radians=\(radians)")
    }

    func registerUserLocationStyleIfNeeded(with manager: LabelManager) {
        guard !didRegisterUserLocationStyle else { return }

        let locationImage = makeUserLocationMarkerImage()
        let iconStyle = PoiIconStyle(symbol: locationImage, anchorPoint: CGPoint(x: 0.5, y: 0.5))
        let locationStyle = PoiStyle(
            styleID: Constants.userLocationStyleID,
            styles: [PerLevelPoiStyle(iconStyle: iconStyle, level: 0)]
        )
        manager.addPoiStyle(locationStyle)

        let fanImage = makeOrbitingDirectionFanImage(
            from: makeUserDirectionMarkerImage(),
            bodySize: CGSize(
                width: Constants.userLocationMarkerDiameter,
                height: Constants.userLocationMarkerDiameter
            )
        )
        let fanIconStyle = PoiIconStyle(symbol: fanImage, anchorPoint: CGPoint(x: 0.5, y: 0.5))
        let fanStyle = PoiStyle(
            styleID: Constants.userDirectionFanStyleID,
            styles: [PerLevelPoiStyle(iconStyle: fanIconStyle, level: 0)]
        )
        manager.addPoiStyle(fanStyle)

        didRegisterUserLocationStyle = true
        RodiLogger.info("Kakao user location marker style registered")
    }


    // MARK: - RodiUserLocationMarkerImages

    func makeOrbitingDirectionFanImage(from fanImage: UIImage, bodySize: CGSize) -> UIImage {
        let canvasSide = max(bodySize.width, bodySize.height)
            + fanImage.size.height * 2
            + Constants.userDirectionFanCanvasPadding * 2
        let canvasSize = CGSize(width: canvasSide, height: canvasSide)
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let bodyRadius = min(bodySize.width, bodySize.height) / 2
        let fanOrigin = CGPoint(
            x: center.x - fanImage.size.width / 2,
            y: center.y - bodyRadius - fanImage.size.height + Constants.userDirectionFanOverlap
        )

        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { _ in
            fanImage.draw(in: CGRect(origin: fanOrigin, size: fanImage.size))
        }
    }

    func makeUserLocationMarkerImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: Constants.userLocationMarkerCanvasSize)
        return renderer.image { context in
            let diameter = Constants.userLocationMarkerDiameter
            let origin = CGPoint(
                x: (Constants.userLocationMarkerCanvasSize.width - diameter) / 2,
                y: (Constants.userLocationMarkerCanvasSize.height - diameter) / 2
            )
            let outerRect = CGRect(origin: origin, size: CGSize(width: diameter, height: diameter))
            let innerRect = outerRect.insetBy(
                dx: Constants.userLocationMarkerBorderWidth,
                dy: Constants.userLocationMarkerBorderWidth
            )

            context.cgContext.saveGState()
            context.cgContext.setShadow(
                offset: .zero,
                blur: 3,
                color: UIColor.black.withAlphaComponent(0.3).cgColor
            )
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: outerRect)
            context.cgContext.restoreGState()

            UIColor(RodiColor.primary).setFill()
            context.cgContext.fillEllipse(in: innerRect)
        }
    }

    func makeUserDirectionMarkerImage() -> UIImage {
        let markerSize = Constants.directionMarkerSize
        let inset = Constants.directionMarkerCanvasInset
        let canvasSize = CGSize(
            width: markerSize.width + inset * 2,
            height: markerSize.height + inset * 2
        )
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { context in
            let triangle = UIBezierPath()
            triangle.move(to: CGPoint(x: canvasSize.width / 2, y: inset))
            triangle.addLine(to: CGPoint(x: inset + markerSize.width, y: inset + markerSize.height))
            triangle.addLine(to: CGPoint(x: inset, y: inset + markerSize.height))
            triangle.close()

            context.cgContext.setShadow(
                offset: .zero,
                blur: 3,
                color: UIColor.black.withAlphaComponent(0.3).cgColor
            )
            UIColor(RodiColor.primary).setFill()
            triangle.fill()
        }
    }
}

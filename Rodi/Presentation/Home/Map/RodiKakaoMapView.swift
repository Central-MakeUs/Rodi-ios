//
//  RodiKakaoMapView.swift
//  Rodi
//

import UIKit
import SnapKit
import Then

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK
#endif

#if canImport(KakaoMapsSDK)
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
        static let oneKilometerFocusLevel = 14
        static let closeSingleLocationLevel = 15
        static let focusAnimationDurationMillis: UInt = 700
        static let userLocationLayerID = "rodi_user_location_layer"
        static let userDirectionLayerID = "rodi_user_direction_layer"
        static let userLocationPoiID = "rodi_user_location_poi"
        static let userDirectionFanPoiID = "rodi_user_direction_fan_poi"
        static let userLocationStyleID = "rodi_user_location_marker"
        static let userDirectionFanStyleID = "rodi_user_direction_fan_marker"
        static let sdkMarkerResourceBundleNames = ["KakaoMapsSDK-SPM_KakaoMapsSDK-SPM", "KakaoMapsSDKBundle"]
        static let sdkMarkerRelativePath = "assets/svc/images/symbols/map_ico_marker.png"
        static let sdkDirectionFanRelativePath = "assets/svc/images/symbols/map_ico_marker_direction.png"
        static let userLocationMarkerScale: CGFloat = 0.35
        static let userDirectionMarkerScale: CGFloat = 0.5
        static let userDirectionFanCanvasPadding: CGFloat = 8
        static let userDirectionFanOverlap: CGFloat = 11
        static let fallbackLocationAssetName = "rodi_user_location_marker_fallback"
        static let fallbackDirectionFanAssetName = "rodi_user_direction_marker_fallback"
        static let fallbackLocationMarkerSize = CGSize(width: 64, height: 64)
        static let fallbackDirectionFanMarkerSize = CGSize(width: 96, height: 96)
        static let routeMarkerLayerID = "rodi_route_marker_layer"
        static let routeShapeLayerID = "rodi_route_shape_layer"
        static let routePolylineShapeID = "rodi_route_polyline"
        static let routePolylineStyleID = "rodi_route_polyline_style"
        static let routeStartMarkerStyleID = "rodi_route_start_marker"
        static let routeWaypointMarkerStyleID = "rodi_route_waypoint_marker"
        static let routeEndMarkerStyleID = "rodi_route_end_marker"
        static let homeMarkerLayerID = "rodi_home_marker_layer"
        static let homeCourseMarkerStyleID = "rodi_home_course_marker"
        static let homeParkingMarkerStyleID = "rodi_home_parking_marker"
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
    var registeredHomeMarkerStyleIDs: Set<String> = []
    var routeMarkerPoiIDs: [String] = []
    var mapEventHandlers: [DisposableEventHandler] = []
    var viewportChangeGeneration = 0
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
        RodiLogger.debug("RodiKakaoMapView init")
        backgroundColor = .systemBackground
        addSubview(mapContainer)
        mapContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
}
#endif

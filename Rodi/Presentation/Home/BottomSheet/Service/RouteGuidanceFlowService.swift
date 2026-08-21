import ActivityKit
import Foundation

/// 외부 길안내 실행에 앞선 측정 준비와 앱 실행을 담당한다.
/// 화면 표시·중복 요청·stale result 판단은 이를 호출하는 reducer가 소유한다.
@MainActor
struct RouteGuidanceFlowService {
    private let routeGuidanceService: RouteGuidanceService
    private let memberRepository: MemberRepository
    private let practiceTrackingService: PracticeTrackingService
    private let directionsService: KakaoDirectionsService

    init(
        memberRepository: MemberRepository,
        practiceTrackingService: PracticeTrackingService,
        directionsService: KakaoDirectionsService,
        routeGuidanceService: RouteGuidanceService
    ) {
        self.memberRepository = memberRepository
        self.practiceTrackingService = practiceTrackingService
        self.directionsService = directionsService
        self.routeGuidanceService = routeGuidanceService
    }

    var launchOption: RouteGuidanceLaunchOption {
        routeGuidanceService.launchOption()
    }

    var hasActiveMeasurement: Bool {
        practiceTrackingService.hasActiveMeasurement
    }

    var activeMeasurementName: String? {
        practiceTrackingService.session?.courseName
    }

    var areLiveActivitiesEnabled: Bool {
        guard #available(iOS 16.1, *) else { return false }
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func savePreferredApp(_ app: RouteGuidanceApp) {
        routeGuidanceService.savePreferredApp(app)
    }

    func cancelActiveMeasurement() {
        practiceTrackingService.cancel()
    }

    func prepareTracking(for request: RouteGuidanceFlowRequest) async -> RouteGuidanceTrackingPreparation {
        let item = RodiCourseItem(placeDetail: request.detail)
        if item.type == .course {
            async let rabbitAssetName = rabbitAssetName()
            async let routePath = courseRoutePath(for: item)
            return startTracking(
                course: item,
                routePath: await routePath,
                rabbitAssetName: await rabbitAssetName
            )
        }

        return startTracking(
            course: item,
            routePath: parkingRoutePath(for: request.detail),
            rabbitAssetName: await rabbitAssetName()
        )
    }

    private func startTracking(
        course: RodiCourseItem,
        routePath: [RodiCoordinate],
        rabbitAssetName: String
    ) -> RouteGuidanceTrackingPreparation {
        switch practiceTrackingService.start(
            course: course,
            routePath: routePath,
            rabbitAssetName: rabbitAssetName
        ) {
        case .started:
            return .started(measurementID: practiceTrackingService.session?.id ?? UUID())
        case .authorizationRequested:
            return .authorizationRequested
        case .reducedAccuracyRequested:
            return .reducedAccuracyRequested
        case .unavailable(let message):
            return .unavailable(message)
        }
    }

    func open(_ request: RouteGuidanceFlowRequest) async -> RouteGuidanceResult {
        await routeGuidanceService.open(
            request.app,
            for: RodiCourseItem(placeDetail: request.detail),
            userLocation: request.userLocation
        )
    }

    func openInstallPage(for app: RouteGuidanceApp) async -> RouteGuidanceResult {
        await routeGuidanceService.openInstallPage(for: app)
    }

    private func rabbitAssetName() async -> String {
        let profile = try? await memberRepository.fetchMyProfile()
        return profile.map { PracticeLiveActivityRabbitAsset.name(for: $0.level) }
            ?? PracticeLiveActivityRabbitAsset.navigation
    }

    private func courseRoutePath(for item: RodiCourseItem) async -> [RodiCoordinate] {
        if let roadPath = try? await directionsService.fetchRoute(points: item.routeOverlayPoints),
           roadPath.count >= 2 {
            return roadPath
        }
        return item.routeOverlayPoints.map(\.coordinate)
    }

    private func parkingRoutePath(for detail: PlaceDetail) -> [RodiCoordinate] {
        let center = RodiCoordinate(latitude: detail.latitude, longitude: detail.longitude)
        return [center, RodiCoordinate(latitude: detail.latitude + 0.00001, longitude: detail.longitude)]
    }
}

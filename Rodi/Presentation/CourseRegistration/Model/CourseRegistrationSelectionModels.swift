import Foundation

struct CourseRegistrationWaypoint: Equatable, Identifiable {
    let id: UUID

    init(id: UUID = UUID()) {
        self.id = id
    }
}

enum CourseRegistrationInputTarget: Hashable {
    case start
    case destination
    case waypoint(UUID)

    var selectionTitle: String {
        switch self {
        case .start: "출발지 선택"
        case .destination: "도착지 선택"
        case .waypoint: "경유지 선택"
        }
    }

    var movingPinAssetName: String {
        switch self {
        case .start: "ic_start_pin"
        case .destination: "ic_arrival_pin"
        case .waypoint: "ic_route_waypoint"
        }
    }

    var inputIconName: String {
        switch self {
        case .start: "ic_course_start"
        case .destination: "ic_course_destination"
        case .waypoint: "ic_course_waypoint"
        }
    }

    var routePointRole: RodiCoursePointRole {
        switch self {
        case .start: .start
        case .destination: .end
        case .waypoint: .waypoint
        }
    }

    var analyticsInputType: String {
        switch self {
        case .start: "start"
        case .destination: "destination"
        case .waypoint: "waypoint"
        }
    }
}

struct CourseRegistrationSelectedPlace: Equatable {
    let name: String
    let coordinate: RodiCoordinate
}

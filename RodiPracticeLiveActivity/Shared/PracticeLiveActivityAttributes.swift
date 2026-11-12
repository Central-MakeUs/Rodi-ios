//
//  PracticeLiveActivityAttributes.swift
//  RodiPracticeLiveActivity
//

import ActivityKit
import Foundation

enum PracticeLiveActivityDeepLink {
    private static let scheme = "rodi"
    private static let host = "live-activity"

    static func url(sessionID: UUID) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.queryItems = [URLQueryItem(name: "sessionID", value: sessionID.uuidString)]
        return components.url
    }

    static func sessionID(from url: URL) -> UUID? {
        guard
            url.scheme == scheme,
            url.host == host,
            let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "sessionID" })?
                .value
        else {
            return nil
        }

        return UUID(uuidString: value)
    }
}

nonisolated enum PracticeLiveActivityPhase: String, Codable, Hashable, Sendable {
    case headingToCourse
    case drivingCourse
    case completed
}

@available(iOS 16.1, *)
nonisolated struct PracticeLiveActivityAttributes: ActivityAttributes, Sendable {
    struct ContentState: Codable, Hashable, Sendable {
        let phaseRawValue: String
        let progress: Double
        let distanceToCourseStartMeters: Int?

        var phase: PracticeLiveActivityPhase {
            PracticeLiveActivityPhase(rawValue: phaseRawValue) ?? .completed
        }
    }

    let sessionID: UUID
    let courseName: String
    let placeTypeRawValue: String
    let rabbitAssetName: String
}

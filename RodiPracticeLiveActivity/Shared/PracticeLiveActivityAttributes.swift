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

@available(iOS 16.1, *)
struct PracticeLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let phaseRawValue: String
        let approachProgress: Double
        let progress: Double
        let distanceToCourseStartMeters: Int?
    }

    let sessionID: UUID
    let courseID: Int
    let courseName: String
    let placeTypeRawValue: String
    let rabbitAssetName: String
}

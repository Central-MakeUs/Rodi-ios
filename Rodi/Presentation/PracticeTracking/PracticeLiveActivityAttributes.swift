//
//  PracticeLiveActivityAttributes.swift
//  Rodi
//

import ActivityKit
import Foundation

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
}

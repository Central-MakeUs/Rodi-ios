//
//  HomeMapCameraPolicy.swift
//  Rodi
//

enum HomeMapCameraPolicy {
    static func zoomLevel(for focus: RodiMapCameraFocus) -> Int {
        switch focus {
        case .normal, .currentLocation, .cluster:
            14
        case .koreaOverview:
            6
        case .closeSingleLocation:
            15
        }
    }
}

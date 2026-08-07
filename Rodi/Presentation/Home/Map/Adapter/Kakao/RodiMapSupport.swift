//
//  RodiMapSupport.swift
//  Rodi
//

import CoreGraphics

extension Optional where Wrapped == RodiCoordinate {
    var logDescription: String {
        switch self {
        case .some(let coordinate):
            RodiLogger.coordinate(coordinate)
        case .none:
            "nil"
        }
    }
}

extension CGFloat {
    var degreesToRadians: CGFloat {
        self * .pi / 180
    }
}

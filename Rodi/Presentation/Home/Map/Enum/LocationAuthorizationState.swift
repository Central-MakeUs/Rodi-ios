//
//  LocationAuthorizationState.swift
//  Rodi
//

import Foundation

enum LocationAuthorizationState: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

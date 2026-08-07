//
//  LocationState.swift
//  Rodi
//
//  Created by mac on 8/5/26.
//

import Foundation

enum LocationState: Equatable {
    case idle
    case requesting
    case resolved
    case unavailable
}

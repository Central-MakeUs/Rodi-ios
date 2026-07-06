//
//  LocationRequestKind.swift
//  Rodi
//

enum LocationRequestKind {
    case initial
    case userInitiated

    var logValue: String {
        switch self {
        case .initial:
            return "initial"
        case .userInitiated:
            return "user_initiated"
        }
    }
}

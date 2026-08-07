//
//  MyRoute.swift
//  Rodi
//

import Foundation

enum MyRoute: Route {
    case settings
    case drivingGoal
    case savedPlaces
    case permissions
    case terms
    case licenses
    case accountManagement
    case contact
    case legalDocument(LegalDocument)

    var id: String {
        switch self {
        case .settings: "my.settings"
        case .drivingGoal: "my.drivingGoal"
        case .savedPlaces: "my.savedPlaces"
        case .permissions: "my.permissions"
        case .terms: "my.terms"
        case .licenses: "my.licenses"
        case .accountManagement: "my.accountManagement"
        case .contact: "my.contact"
        case .legalDocument(let document): "my.legalDocument.\(document.rawValue)"
        }
    }
}

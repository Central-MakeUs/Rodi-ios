//
//  MyRoute.swift
//  Rodi
//

import Foundation

enum MyRoute: Route {
    case settings
    case drivingGoal
    case savedPlaces
    case practiceRecords
    case myPosts
    case courseRegistration
    case permissions
    case terms
    case licenses
    case accountManagement
    case blockedMembers
    case contact
    case legalDocument(LegalDocument)

    var id: String {
        switch self {
        case .settings: "my.settings"
        case .drivingGoal: "my.drivingGoal"
        case .savedPlaces: "my.savedPlaces"
        case .practiceRecords: "my.practiceRecords"
        case .myPosts: "my.posts"
        case .courseRegistration: "my.courseRegistration"
        case .permissions: "my.permissions"
        case .terms: "my.terms"
        case .licenses: "my.licenses"
        case .accountManagement: "my.accountManagement"
        case .blockedMembers: "my.blockedMembers"
        case .contact: "my.contact"
        case .legalDocument(let document): "my.legalDocument.\(document.rawValue)"
        }
    }
}

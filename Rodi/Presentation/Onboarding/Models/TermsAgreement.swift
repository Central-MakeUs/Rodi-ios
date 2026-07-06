//
//  TermsAgreement.swift
//  Rodi
//

import Foundation

enum TermsAgreement: String, CaseIterable, Identifiable {
    case service
    case privacy
    case location

    var id: String { rawValue }

    var title: String {
        switch self {
        case .service:
            LegalDocument.service.requiredTitle
        case .privacy:
            LegalDocument.privacy.requiredTitle
        case .location:
            LegalDocument.location.requiredTitle
        }
    }

    var url: URL {
        switch self {
        case .service:
            LegalDocument.service.url
        case .privacy:
            LegalDocument.privacy.url
        case .location:
            LegalDocument.location.url
        }
    }
}

//
//  LegalDocument.swift
//  Rodi
//
//  Created by Codex on 6/29/26.
//

import Foundation

enum LegalDocument: String, CaseIterable, Identifiable {
    case service
    case privacy
    case location

    var id: String { rawValue }

    var title: String {
        switch self {
        case .service:
            "서비스 이용약관"
        case .privacy:
            "개인정보처리방침"
        case .location:
            "위치기반 서비스 이용약관"
        }
    }

    var requiredTitle: String {
        "\(title)(필수)"
    }

    var url: URL {
        switch self {
        case .service:
            URL(string: "https://sites.google.com/view/dororongggggg/홈")!
        case .privacy:
            URL(string: "https://sites.google.com/view/dorororongg/홈")!
        case .location:
            URL(string: "https://sites.google.com/view/dororonggg/홈")!
        }
    }

    static let supportURL = URL(string: "https://sites.google.com/view/dororong/홈")!
    static let openSourceLicenseURL = URL(string: "https://app.notion.com/p/3a493d5b4d4880d48625e977496a70c8?source=copy_link")!
}

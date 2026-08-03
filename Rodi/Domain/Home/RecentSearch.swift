//
//  RecentSearchRepository.swift
//  Rodi
//

import Foundation

struct RecentSearch: Equatable, Identifiable {
    enum Kind: String, Equatable {
        case region = "REGION"
        case place = "PLACE"
    }

    let id: Int
    let kind: Kind
    let keyword: String
    let placeID: Int?
}

struct RecentSearchRegistration: Equatable {
    let kind: RecentSearch.Kind
    let keyword: String
    let placeID: Int?

    init(kind: RecentSearch.Kind, keyword: String, placeID: Int? = nil) {
        self.kind = kind
        self.keyword = keyword
        self.placeID = placeID
    }
}

//
//  RecentSearchMapper.swift
//  Rodi
//

import Foundation

enum RecentSearchMapper {
    static func search(
        from dto: RecentSearchDTO
    ) throws(NetworkError) -> RecentSearch {
        guard let kind = RecentSearch.Kind(rawValue: dto.type) else {
            throw .decodingFail
        }

        return RecentSearch(
            id: dto.id,
            kind: kind,
            keyword: dto.keyword,
            placeID: dto.placeId
        )
    }
}

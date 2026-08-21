import Foundation

nonisolated enum RecentSearchMapper {
    static func search(
        from dto: RecentSearchDTO
    ) throws(NetworkError) -> RecentSearch {
        guard let kind = RecentSearch.Kind(rawValue: dto.type) else {
            throw .decodingFail
        }

        return .init(
            id: try int(from: dto.id),
            kind: kind,
            keyword: dto.keyword,
            placeID: dto.placeId
        )
    }

    private static func int(from value: Int64) throws(NetworkError) -> Int {
        guard let value = Int(exactly: value) else {
            throw .decodingFail
        }
        return value
    }
}

nonisolated extension RecentSearchRegisterRequestDTO {
    init(_ registration: RecentSearchRegistration) {
        self.init(
            type: registration.kind.rawValue,
            keyword: registration.keyword,
            placeId: registration.placeID
        )
    }
}

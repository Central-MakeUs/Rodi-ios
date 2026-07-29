//
//  KoreanAdministrativeAreaSearchService.swift
//  Rodi
//

import Foundation

protocol KoreanAdministrativeAreaSearching {
    func search(query: String) -> [KoreanAdministrativeArea]
}

final class KoreanAdministrativeAreaSearchService: KoreanAdministrativeAreaSearching {
    static let shared = KoreanAdministrativeAreaSearchService()

    private enum Constants {
        static let resourceName = "korean_administrative_areas"
        static let resourceExtension = "json"
        static let resultLimit = 4
    }

    private let areas: [KoreanAdministrativeArea]

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(
            forResource: Constants.resourceName,
            withExtension: Constants.resourceExtension
        ) else {
            RodiLogger.error("Administrative area catalog resource is missing")
            areas = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            areas = try JSONDecoder().decode(KoreanAdministrativeAreaCatalog.self, from: data).areas
        } catch {
            RodiLogger.error("Administrative area catalog decoding failed error=\(error.localizedDescription)")
            areas = []
        }
    }

    func search(query: String) -> [KoreanAdministrativeArea] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else { return [] }

        return areas
            .compactMap { area -> (area: KoreanAdministrativeArea, score: Int)? in
                guard let score = matchScore(for: area, query: normalizedQuery) else { return nil }
                return (area, score)
            }
            .sorted { lhs, rhs in
                lhs.area.searchDisplayName.compare(
                    rhs.area.searchDisplayName,
                    locale: Locale(identifier: "ko_KR")
                ) == .orderedAscending
            }
            .prefix(Constants.resultLimit)
            .map(\.area)
    }

    private func matchScore(for area: KoreanAdministrativeArea, query: String) -> Int? {
        let displayName = normalize(area.displayName)
        if displayName == query { return 0 }
        if area.aliases.contains(where: { normalize($0) == query }) { return 1 }
        if displayName.hasPrefix(query) { return 2 }
        if area.aliases.contains(where: { normalize($0).hasPrefix(query) }) { return 3 }
        if displayName.contains(query) { return 4 }
        if area.aliases.contains(where: { normalize($0).contains(query) }) { return 5 }
        return nil
    }

    private func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
    }
}

//
//  CourseRegistrationAdministrativeRegionService.swift
//  Rodi
//

import Foundation

struct CourseRegistrationAdministrativeRegionService {
    private let areas: [Area]

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(
            forResource: "korean_administrative_areas",
            withExtension: "json"
        ),
        let data = try? Data(contentsOf: url),
        let catalog = try? JSONDecoder().decode(Catalog.self, from: data)
        else {
            areas = []
            return
        }

        areas = catalog.areas
    }

    func suggestions(
        for query: String,
        limit: Int = 4
    ) -> [CourseRegistrationRegionSuggestion] {
        let normalizedQuery = Self.normalize(query)
        guard !normalizedQuery.isEmpty else { return [] }

        return areas
            .compactMap { area -> Match? in
                let aliases = area.searchableAliases
                let normalizedDisplayName = Self.normalize(area.displayName)

                let rank: Int
                if aliases.contains(normalizedQuery) {
                    rank = 0
                } else if normalizedDisplayName.hasPrefix(normalizedQuery) {
                    rank = 1
                } else if aliases.contains(where: { $0.hasPrefix(normalizedQuery) }) {
                    rank = 2
                } else if aliases.contains(where: { $0.contains(normalizedQuery) }) {
                    rank = 3
                } else {
                    return nil
                }

                return Match(area: area, rank: rank)
            }
            .sorted { lhs, rhs in
                if lhs.rank != rhs.rank {
                    return lhs.rank < rhs.rank
                }
                if lhs.area.level.sortOrder != rhs.area.level.sortOrder {
                    return lhs.area.level.sortOrder < rhs.area.level.sortOrder
                }
                return lhs.area.regionDisplayName < rhs.area.regionDisplayName
            }
            .prefix(limit)
            .map { match in
                CourseRegistrationRegionSuggestion(
                    id: match.area.id,
                    displayName: match.area.regionDisplayName,
                    searchQuery: match.area.keywordSearchQuery
                )
            }
    }
}

private extension CourseRegistrationAdministrativeRegionService {
    struct Catalog: Decodable {
        let areas: [Area]
    }

    struct Area: Decodable {
        let id: String
        let level: Level
        let displayName: String
        let parentName: String?
        let aliases: [String]

        var searchableAliases: [String] {
            let meaningfulAliases: [String]
            switch level {
            case .sido:
                meaningfulAliases = aliases
            case .sigungu, .municipalCity:
                meaningfulAliases = aliases.filter { alias in
                    CourseRegistrationAdministrativeRegionService.normalize(alias)
                        .contains(CourseRegistrationAdministrativeRegionService.normalize(localDisplayName))
                }
            }

            return Set(meaningfulAliases + [displayName, keywordSearchQuery])
                .map(CourseRegistrationAdministrativeRegionService.normalize)
        }

        var regionDisplayName: String {
            switch level {
            case .sido:
                return aliases.max(by: { $0.count < $1.count }) ?? displayName
            case .sigungu, .municipalCity:
                return keywordSearchQuery
            }
        }

        var keywordSearchQuery: String {
            guard let parentName else { return displayName }

            let spacedAliases = aliases
                .filter { $0.contains(" ") && $0.hasSuffix(localDisplayName) }
                .sorted { lhs, rhs in
                    if lhs.count != rhs.count { return lhs.count < rhs.count }
                    return lhs < rhs
                }

            if let shortestAlias = spacedAliases.first {
                return shortestAlias
            }
            return "\(parentName) \(localDisplayName)"
        }

        var localDisplayName: String {
            guard let parentName else { return displayName }

            let parentPrefix = "\(parentName) "
            guard displayName.hasPrefix(parentPrefix) else { return displayName }

            return String(displayName.dropFirst(parentPrefix.count))
        }
    }

    enum Level: String, Decodable {
        case sido
        case sigungu
        case municipalCity

        var sortOrder: Int {
            switch self {
            case .sido:
                0
            case .sigungu, .municipalCity:
                1
            }
        }
    }

    struct Match {
        let area: Area
        let rank: Int
    }

    nonisolated static func normalize(_ value: String) -> String {
        value
            .lowercased()
            .filter { !$0.isWhitespace }
    }
}

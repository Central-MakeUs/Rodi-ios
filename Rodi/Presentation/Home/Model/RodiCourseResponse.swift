//
//  RodiCourseResponse.swift
//  Rodi
//

import Foundation

struct RodiCourseResponse: Decodable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: RodiCourseResult
}

struct RodiCourseResult: Decodable {
    let region: String
    let totalCount: Int
    let items: [RodiCourseItem]

    private enum CodingKeys: String, CodingKey {
        case region
        case totalCount
        case items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        region = try container.decode(String.self, forKey: .region)
        totalCount = try container.decode(Int.self, forKey: .totalCount)
        items = try container.decode(LossyDecodableArray<RodiCourseItem>.self, forKey: .items).elements
    }
}

private struct LossyDecodableArray<Element: Decodable>: Decodable {
    let elements: [Element]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var decodedElements: [Element] = []
        var skippedCount = 0

        while !container.isAtEnd {
            do {
                decodedElements.append(try container.decode(Element.self))
            } catch {
                skippedCount += 1
                #if DEBUG
                RodiLogger.warning("Rodi item skipped during JSON decode index=\(container.currentIndex), error=\(error)")
                #endif
                _ = try? container.decode(DiscardedDecodableValue.self)
            }
        }

        elements = decodedElements

        #if DEBUG
        if skippedCount > 0 {
            RodiLogger.warning("Rodi JSON loaded with skipped invalid item count=\(skippedCount)")
        }
        #endif
    }
}

private struct DiscardedDecodableValue: Decodable {}

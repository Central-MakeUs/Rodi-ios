//
//  RodiCourseLoader.swift
//  Rodi
//

import Foundation

enum RodiCourseLoader {
    static func loadBundledItems() throws -> [RodiCourseItem] {
        guard let url = Bundle.main.url(forResource: "rodi_dummy_items", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(RodiCourseResponse.self, from: data).result.items
    }
}

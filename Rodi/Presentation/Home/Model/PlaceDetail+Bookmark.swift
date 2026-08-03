//
//  PlaceDetail+Bookmark.swift
//  Rodi
//

import Foundation

extension PlaceDetail {
    func updatingBookmark(isBookmarked: Bool) -> PlaceDetail {
        PlaceDetail(
            id: id,
            type: type,
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            practiceTypes: practiceTypes,
            bookmarkCount: max(0, bookmarkCount + (isBookmarked == self.isBookmarked ? 0 : (isBookmarked ? 1 : -1))),
            isBookmarked: isBookmarked,
            course: course,
            parking: parking
        )
    }
}

import Foundation

struct MemberPlaceFilterTagsUpdateRequestDTO: Encodable {
    let filterTags: [String]
    
    init(_ tags: [PlacePracticeType]) {
        filterTags = tags.map(\.rawValue)
    }
}

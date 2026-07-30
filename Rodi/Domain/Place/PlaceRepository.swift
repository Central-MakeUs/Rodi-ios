//
//  PlaceRepository.swift
//  Rodi
//

import Foundation

protocol PlaceRepository {
    /// 지도 마커와 클라이언트 클러스터링용 전체 경량 좌표 목록입니다. 공개 API입니다.
    func fetchCoordinates() async throws(NetworkError) -> [PlaceCoordinate]

    /// viewport 안 장소를 현위치 거리순 cursor pagination으로 조회합니다.
    /// 회원 조회는 서버에 저장된 연습유형 정렬 필터를 반영합니다.
    func fetchPlaces(query: PlaceListQuery, access: PlaceListAccess) async throws(NetworkError) -> PlaceCursorPage

    /// 키워드로 코스와 주차장을 검색합니다. JWT가 필요합니다.
    func searchPlaces(query: PlaceSearchQuery) async throws(NetworkError) -> PlaceCursorPage

    /// 현재 회원이 저장한 장소를 최신 저장순으로 cursor pagination 조회합니다. JWT가 필요합니다.
    func fetchBookmarkedPlaces(query: PlaceBookmarkListQuery) async throws(NetworkError) -> PlaceCursorPage

    /// 장소 상세와 회원별 북마크 여부를 조회합니다. JWT가 필요합니다.
    func fetchPlaceDetail(id: Int) async throws(NetworkError) -> PlaceDetail

    func bookmark(placeID: Int) async throws(NetworkError)
    func unbookmark(placeID: Int) async throws(NetworkError)
}

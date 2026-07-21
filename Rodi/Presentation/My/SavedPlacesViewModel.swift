//
//  SavedPlacesViewModel.swift
//  Rodi
//

import Combine
import Foundation

@MainActor
final class SavedPlacesViewModel: ObservableObject {
    @Published private(set) var items: [PlaceListItem] = []
    @Published private(set) var totalCount: Int?
    @Published private(set) var isInitialLoading = false
    @Published private(set) var isNextPageLoading = false
    @Published private(set) var errorMessage: String?

    private let placeRepository: PlaceRepository
    private var nextCursor: String?
    private var hasNextPage = false

    init(placeRepository: PlaceRepository) {
        self.placeRepository = placeRepository
    }

    func loadIfNeeded() async {
        guard items.isEmpty, !isInitialLoading else { return }
        await reload()
    }

    func reload() async {
        guard !isInitialLoading else { return }

        isInitialLoading = true
        errorMessage = nil
        defer { isInitialLoading = false }

        do {
            let page = try await placeRepository.fetchBookmarkedPlaces(query: PlaceBookmarkListQuery())
            applyFirstPage(page)
        } catch {
            errorMessage = message(for: error)
        }
    }

    func loadNextPageIfNeeded(after item: PlaceListItem) async {
        guard item.id == items.last?.id,
              hasNextPage,
              let nextCursor,
              !isInitialLoading,
              !isNextPageLoading else {
            return
        }

        isNextPageLoading = true
        errorMessage = nil
        defer { isNextPageLoading = false }

        do {
            let page = try await placeRepository.fetchBookmarkedPlaces(
                query: PlaceBookmarkListQuery(cursor: nextCursor)
            )
            append(page)
        } catch {
            errorMessage = message(for: error)
        }
    }

    private func applyFirstPage(_ page: PlaceCursorPage) {
        items = page.items
        totalCount = page.totalCount ?? page.items.count
        hasNextPage = page.hasNext
        nextCursor = page.nextCursor
    }

    private func append(_ page: PlaceCursorPage) {
        let existingIDs = Set(items.map(\.id))
        items.append(contentsOf: page.items.filter { !existingIDs.contains($0.id) })
        hasNextPage = page.hasNext
        nextCursor = page.nextCursor
    }

    private func message(for error: Error) -> String {
        if case NetworkError.networkUnavailable = error {
            return "인터넷 연결을 확인한 뒤 다시 시도해 주세요."
        }
        return "저장 목록을 불러오지 못했어요."
    }
}

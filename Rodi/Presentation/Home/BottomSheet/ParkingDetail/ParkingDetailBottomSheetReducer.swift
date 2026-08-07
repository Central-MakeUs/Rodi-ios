//
//  ParkingDetailBottomSheetReducer.swift
//  Rodi
//

import Foundation

struct ParkingDetailBottomSheetReducer: Reducer {
    struct State {
        var detail: PlaceDetail?
        var isBookmarkUpdating = false
    }

    enum Action {
        case present(PlaceDetail, source: String)
        case dismiss
        case toggleBookmark
        case bookmarkUpdated(placeID: Int, isBookmarked: Bool, source: String)
        case bookmarkFailed(previousDetail: PlaceDetail, message: String)
        case delegate(Delegate)
    }

    enum Delegate {
        case dismissed
        case focusMap(RodiCoordinate)
        case requestAuthentication
        case showSnackbar(String)
    }

    private let placeRepository: PlaceRepository
    private let hasActiveSession: () -> Bool
    private let onDelegate: (Delegate) -> Void

    init(placeRepository: PlaceRepository,
         hasActiveSession: @escaping () -> Bool,
         onDelegate: @escaping (Delegate) -> Void = { _ in }) {
        self.placeRepository = placeRepository
        self.hasActiveSession = hasActiveSession
        self.onDelegate = onDelegate
    }
}


// MARK: - Core Logics
extension ParkingDetailBottomSheetReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .present(let detail, _):
            guard detail.type == .parking else { return .none }
            state.detail = detail
            state.isBookmarkUpdating = false
            RodiAnalytics.track(.placeDetailOpened(source: "home", placeType: detail.type.rawValue))
            return .send(.delegate(.focusMap(RodiCoordinate(latitude: detail.latitude, longitude: detail.longitude))))

        case .dismiss:
            guard state.detail != nil else { return .none }
            state = State()
            return .send(.delegate(.dismissed))

        case .toggleBookmark:
            guard let detail = state.detail, !state.isBookmarkUpdating else { return .none }
            guard hasActiveSession() else { return .send(.delegate(.requestAuthentication)) }
            let previousDetail = detail
            let isBookmarked = !detail.isBookmarked
            state.detail = detail.updatingBookmark(isBookmarked: isBookmarked)
            state.isBookmarkUpdating = true
            return updateBookmarkEffect(placeID: detail.id, isBookmarked: isBookmarked, previousDetail: previousDetail)

        case .bookmarkUpdated(let id, let isBookmarked, let source):
            guard state.detail?.id == id else { return .none }
            state.detail = state.detail?.updatingBookmark(isBookmarked: isBookmarked)
            state.isBookmarkUpdating = false
            RodiAnalytics.track(.bookmarkUpdated(isBookmarked: isBookmarked, source: source, placeType: PlaceType.parking.rawValue))
            return .send(.delegate(.showSnackbar(isBookmarked ? "북마크를 저장했어요." : "북마크를 해제했어요.")))

        case .bookmarkFailed(let previousDetail, let message):
            guard state.detail?.id == previousDetail.id else { return .none }
            state.detail = previousDetail
            state.isBookmarkUpdating = false
            return .send(.delegate(.showSnackbar(message)))

        case .delegate(let delegate):
            onDelegate(delegate)
        }
        return .none
    }

    private func updateBookmarkEffect(placeID: Int, isBookmarked: Bool, previousDetail: PlaceDetail) -> Effect<Action> {
        let repository = placeRepository
        return .run { send in
            do {
                if isBookmarked { try await repository.bookmark(placeID: placeID) }
                else { try await repository.unbookmark(placeID: placeID) }
                await send(.bookmarkUpdated(placeID: placeID, isBookmarked: isBookmarked, source: "home"))
            } catch is CancellationError {
                return
            } catch {
                if requiresAuthentication(error) { await send(.delegate(.requestAuthentication)) }
                else { await send(.bookmarkFailed(previousDetail: previousDetail, message: "북마크를 \(isBookmarked ? "저장" : "해제")하지 못했어요.")) }
            }
        }
        .cancelTask(id: BottomSheetEffectID.bookmarkUpdating)
    }

    private func requiresAuthentication(_ error: Error) -> Bool {
        guard let networkError = error as? NetworkError else { return false }
        return switch networkError {
        case .refreshFailGoRoot, .httpStatusCode(401): true
        case .apiError(let code, _, _): code.hasPrefix("AUTH_401") || code == "AUTH_400_1"
        default: false
        }
    }
}

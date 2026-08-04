//
//  HomePracticeFilterReducer.swift
//  Rodi
//

import Foundation

struct HomePracticeFilterReducer: Reducer {
    struct State {
        var appliedSelection: HomePracticeFilterSelection
        var draftSelection: HomePracticeFilterSelection
        var isApplying = false

        init(filterStore: HomePracticeFilterStore = .init()) {
            let selection = filterStore.load()
            appliedSelection = selection
            draftSelection = selection
        }

        var canApply: Bool {
            !isApplying && draftSelection.filterTags != appliedSelection.filterTags
        }
    }

    enum Action {
        case present(mediumHeight: CGFloat)
        case dismiss
        case selectCategory(HomePracticeCategory)
        case toggleType(PlacePracticeType)
        case selectAll
        case reset
        case apply
        case applied(HomePracticeFilterSelection)
        case authenticationRequired
        case failed(String)
        case delegate(Delegate)
    }

    enum Delegate {
        case presentFilter(mediumHeight: CGFloat)
        case reloadPlaceList
        case requestAuthentication
        case showSnackbar(String)
    }

    private let memberRepository: MemberRepository
    private let filterStore: HomePracticeFilterStore
    private let hasActiveSession: () -> Bool

    init(
        memberRepository: MemberRepository,
        filterStore: HomePracticeFilterStore,
        hasActiveSession: @escaping () -> Bool
    ) {
        self.memberRepository = memberRepository
        self.filterStore = filterStore
        self.hasActiveSession = hasActiveSession
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .present(let mediumHeight):
            guard hasActiveSession() else {
                return .send(.delegate(.requestAuthentication))
            }
            state.draftSelection = state.appliedSelection
            RodiAnalytics.track(.practiceFilterOpened(presentation: "bottom_sheet"))
            return .send(.delegate(.presentFilter(mediumHeight: mediumHeight)))

        case .dismiss:
            state.isApplying = false
            state.draftSelection = state.appliedSelection

        case .selectCategory(let category):
            guard !state.isApplying else { return .none }
            state.draftSelection.selectCategory(category)

        case .toggleType(let type):
            guard !state.isApplying else { return .none }
            state.draftSelection.toggleType(type)

        case .selectAll:
            guard !state.isApplying else { return .none }
            state.draftSelection.selectAll()

        case .reset:
            guard !state.isApplying else { return .none }
            state.draftSelection = .default
            RodiAnalytics.track(.practiceFilterReset)

        case .apply:
            guard state.canApply else { return .none }
            state.isApplying = true
            return updateFilterEffect(selection: state.draftSelection)

        case .applied(let selection):
            state.appliedSelection = selection
            state.draftSelection = selection
            state.isApplying = false
            filterStore.save(selection)
            RodiAnalytics.track(
                .practiceFilterApplied(
                    category: selection.category.rawValue,
                    selectedTagCount: selection.filterTags.count,
                    isAll: selection.isAllSelected
                )
            )
            return .send(.delegate(.reloadPlaceList))

        case .authenticationRequired:
            state.isApplying = false
            return .send(.delegate(.requestAuthentication))

        case .failed(let message):
            state.isApplying = false
            return .send(.delegate(.showSnackbar(message)))

        case .delegate:
            break
        }

        return .none
    }
}

private extension HomePracticeFilterReducer {
    func updateFilterEffect(selection: HomePracticeFilterSelection) -> Effect<Action> {
        let repository = memberRepository
        return .run { send in
            do {
                try await repository.updatePlaceFilterTags(selection.filterTags)
                await send(.applied(selection))
            } catch is CancellationError {
                return
            } catch {
                RodiLogger.warning("Home practice filter update failed. error=\(error.localizedDescription)")
                if requiresAuthentication(error) {
                    await send(.authenticationRequired)
                    return
                }
                await send(.failed("필터를 적용하지 못했어요. 다시 시도해 주세요."))
            }
        }
        .cancelTask(id: HomeEffectID.practiceFilterUpdating)
    }

    func requiresAuthentication(_ error: Error) -> Bool {
        guard let networkError = error as? NetworkError else { return false }
        return switch networkError {
        case .refreshFailGoRoot, .httpStatusCode(401): true
        case .apiError(let code, _, _): code.hasPrefix("AUTH_401") || code == "AUTH_400_1"
        default: false
        }
    }
}

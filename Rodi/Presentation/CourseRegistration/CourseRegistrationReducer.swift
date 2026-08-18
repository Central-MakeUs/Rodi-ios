import CoreLocation
import Foundation

@MainActor
struct CourseRegistrationReducer: Reducer {
    struct State: Equatable {
        enum Route: Equatable {
            case tutorial
            case registration
            case registrationSearch(CourseRegistrationInputTarget)
            case pinEditing
            case pinEditSearch
            case details
        }

        var route: Route
        var tutorialPage = 0
        var isCompletingTutorial = false
        var errorMessage: String?
        var tutorialCompletionRevision = 0
        var waypoints: [CourseRegistrationWaypoint] = []
        var selectedPlaces: [CourseRegistrationInputTarget: CourseRegistrationSelectedPlace] = [:]
        var routePath: [RodiCoordinate] = []
        var isRouteLoading = false
        var routeRequestRevision = 0
        var map = CourseRegistrationMapState()
        var hasTrackedRegistrationOpened = false
        var pinEdit: CourseRegistrationPinEditState?
        var detailsLoadState: CourseRegistrationDetailsLoadState = .idle
        var detailsDraft = CourseRegistrationDetailsDraft()
        var detailsLoadRevision = 0
        var isDetailsDiscardConfirmationPresented = false
        var isRegistrationDiscardConfirmationPresented = false
        var isSubmittingCourse = false
        var isCourseRegistrationCompletionPresented = false
        var courseRegistrationCompletionRevision = 0
        var courseRegistrationExitRevision = 0
        var alertToast: CourseRegistrationAlertToastState?
        var alertToastRevision = 0

        init(isCourseTutorialCompleted: Bool) {
            route = isCourseTutorialCompleted ? .registration : .tutorial
            map.selectionTarget = isCourseTutorialCompleted ? .start : nil
        }
    }

    enum Action {
        case tutorialPageChanged(Int)
        case tutorialTapped
        case completeTutorialTapped
        case tutorialCompletionFinished(Result<Void, NetworkError>)
        case tutorialCompletionSynced
        case errorDismissed

        case registrationCloseTapped
        case registrationDiscardConfirmed
        case registrationDiscardCancelled

        case waypointAddTapped
        case waypointRemoveTapped(UUID)
        case mapAppeared
        case currentLocationTapped
        case currentLocationResolved(
            CourseRegistrationLocationRequest,
            CourseRegistrationMapService.CurrentLocationResult
        )
        case mapViewportChanged(RodiCoordinate, isUserInitiated: Bool)
        case placeSelectionTapped
        case reverseGeocodingFinished(
            CourseRegistrationAddressRequest,
            Result<String, CourseRegistrationAddressLookupError>
        )
        case selectionCompletionTapped
        case registrationCompletionTapped
        case registrationFormLoaded(Int, Result<CourseRegistrationForm, NetworkError>)
        case registrationFormRetryTapped
        case detailsCategoryTapped(String)
        case detailsPracticeTypeTapped(String)
        case detailsCautionChanged(String)
        case detailsDescriptionChanged(String)
        case detailsBackTapped
        case detailsDiscardConfirmed
        case detailsDiscardCancelled
        case detailsSubmitTapped
        case courseRegistrationFinished(Result<CourseRegistrationResult, NetworkError>)
        case courseRegistrationCompletionConfirmed
        case alertToastDismissed(Int)
        case routePointTapped(Int)
        case inputTargetTapped(CourseRegistrationInputTarget)
        case registrationSearchDismissed
        case registrationSearchResultSelected(CourseRegistrationPlaceSearchItem)

        case pinEditAddressTapped
        case pinEditSearchDismissed
        case pinEditSearchResultSelected(CourseRegistrationPlaceSearchItem)
        case pinEditCandidateAddressFinished(
            CourseRegistrationPinEditAddressRequest,
            Result<String, CourseRegistrationAddressLookupError>
        )
        case pinEditSelectionTapped
        case pinEditRetryTapped
        case pinEditBackTapped
        case pinEditCompletionTapped
        case pinEditRouteFinished(Int, Result<[RodiCoordinate], KakaoDirectionsError>)
        case initialRouteFinished(Int, Result<[RodiCoordinate], KakaoDirectionsError>)
    }

    private let memberRepository: MemberRepository
    private let courseRepository: CourseRepository
    private let mapService: CourseRegistrationMapService
    private let directionsService: KakaoDirectionsService

    init(
        memberRepository: MemberRepository,
        courseRepository: CourseRepository,
        mapService: CourseRegistrationMapService? = nil,
        directionsService: KakaoDirectionsService = .init()
    ) {
        self.memberRepository = memberRepository
        self.courseRepository = courseRepository
        self.mapService = mapService ?? CourseRegistrationMapService()
        self.directionsService = directionsService
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .tutorialPageChanged(let page):
            state.tutorialPage = min(max(page, 0), 2)

        case .tutorialTapped:
            guard state.route == .tutorial, state.tutorialPage < 2 else { return .none }
            state.tutorialPage += 1

        case .completeTutorialTapped:
            guard state.route == .tutorial, state.tutorialPage == 2, !state.isCompletingTutorial else {
                return .none
            }
            state.isCompletingTutorial = true
            state.errorMessage = nil
            return .run { send in
                do {
                    _ = try await memberRepository.completeCourseTutorial()
                    await send(.tutorialCompletionFinished(.success(())))
                } catch let error as NetworkError {
                    await send(.tutorialCompletionFinished(.failure(error)))
                } catch {
                    await send(.tutorialCompletionFinished(.failure(.unknown(errorCode: "unknown"))))
                }
            }

        case .tutorialCompletionFinished(let result):
            state.isCompletingTutorial = false
            switch result {
            case .success:
                state.route = .registration
                beginSelection(.start, state: &state)
                state.tutorialCompletionRevision += 1
            case .failure:
                state.errorMessage = "튜토리얼 완료를 저장하지 못했어요. 다시 시도해 주세요."
            }

        case .tutorialCompletionSynced:
            break

        case .errorDismissed:
            state.errorMessage = nil

        case .registrationCloseTapped:
            guard state.route == .registration else { return .none }
            if registrationHasInput(state) {
                state.isRegistrationDiscardConfirmationPresented = true
            } else {
                state.courseRegistrationExitRevision += 1
            }

        case .registrationDiscardConfirmed:
            guard state.isRegistrationDiscardConfirmationPresented else { return .none }
            state.isRegistrationDiscardConfirmationPresented = false
            resetRegistrationState(state: &state)
            state.courseRegistrationExitRevision += 1

        case .registrationDiscardCancelled:
            state.isRegistrationDiscardConfirmationPresented = false

        case .waypointAddTapped:
            guard state.route == .registration,
                  state.map.selectionTarget == nil,
                  state.waypoints.count < 3
            else {
                return .none
            }
            let waypoint = CourseRegistrationWaypoint()
            state.waypoints.append(waypoint)
            state.routePath = []
            RodiAnalytics.track(
                .courseRegistrationWaypointChanged(action: "added", waypointCount: state.waypoints.count)
            )
            beginSelection(.waypoint(waypoint.id), state: &state)

        case .waypointRemoveTapped(let id):
            guard state.route == .registration,
                  state.waypoints.contains(where: { $0.id == id })
            else {
                return .none
            }
            state.waypoints.removeAll { $0.id == id }
            state.selectedPlaces[.waypoint(id)] = nil
            state.routePath = []
            RodiAnalytics.track(
                .courseRegistrationWaypointChanged(action: "removed", waypointCount: state.waypoints.count)
            )

            if state.map.selectionTarget == .waypoint(id) {
                state.map.selectionTarget = nil
                state.map.candidateCoordinate = nil
                state.map.hasSelectedCurrentTarget = false
                state.map.isAddressResolving = false
                state.map.addressRequestRevision += 1
            }

        case .mapAppeared:
            // 검색·핀 수정 화면에서 등록 화면으로 복귀할 때도 onAppear가 다시 호출된다.
            // 이때 초기 현재 위치 응답이 검색 결과의 카메라 이동을 덮어쓰지 않도록,
            // 세션의 최초 진입에서만 자동 위치를 요청한다.
            guard state.route == .registration, !state.map.hasRequestedInitialLocation else { return .none }
            if !state.hasTrackedRegistrationOpened {
                state.hasTrackedRegistrationOpened = true
                RodiAnalytics.track(.courseRegistrationOpened)
            }
            state.map.hasRequestedInitialLocation = true
            state.map.locationRequestRevision += 1
            return requestCurrentLocation(.init(
                revision: state.map.locationRequestRevision,
                scope: .registration,
                source: .initial
            ))

        case .currentLocationTapped:
            switch state.route {
            case .registration:
                state.map.locationRequestRevision += 1
                state.map.isCurrentLocationActive = true
                return requestCurrentLocation(.init(
                    revision: state.map.locationRequestRevision,
                    scope: .registration,
                    source: .userAction
                ))
            case .pinEditing:
                guard var pinEdit = state.pinEdit, pinEdit.temporaryPlace == nil else { return .none }
                pinEdit.locationRequestRevision += 1
                pinEdit.isCurrentLocationActive = true
                state.pinEdit = pinEdit
                return requestCurrentLocation(.init(
                    revision: pinEdit.locationRequestRevision,
                    scope: .pinEditing,
                    source: .userAction
                ))
            default:
                return .none
            }

        case .currentLocationResolved(let request, let result):
            switch request.scope {
            case .registration:
                guard state.route == .registration,
                      request.revision == state.map.locationRequestRevision
                else {
                    return .none
                }
                if case .resolved(let coordinate) = result {
                    state.map.cameraTarget = coordinate
                    state.map.cameraRequestID += 1
                }
                if request.source == .userAction {
                    state.map.isCurrentLocationActive = false
                    if let message = currentLocationFailureMessage(for: result) {
                        RodiAnalytics.track(.courseRegistrationFailed(stage: "current_location"))
                        state.errorMessage = message
                    }
                } else if request.source == .initial {
                    state.map.isCurrentLocationActive = false
                }
            case .pinEditing:
                guard state.route == .pinEditing,
                      var pinEdit = state.pinEdit,
                      request.revision == pinEdit.locationRequestRevision,
                      pinEdit.temporaryPlace == nil
                else {
                    return .none
                }
                if case .resolved(let coordinate) = result {
                    pinEdit.cameraTarget = coordinate
                    pinEdit.cameraRequestID += 1
                    pinEdit.candidateCoordinate = coordinate
                    pinEdit.candidateAddress = nil
                    pinEdit.isCurrentLocationActive = false
                    state.pinEdit = pinEdit
                    return .none
                }
                pinEdit.isCurrentLocationActive = false
                state.pinEdit = pinEdit
                if request.source == .userAction,
                   let message = currentLocationFailureMessage(for: result) {
                    RodiAnalytics.track(.courseRegistrationFailed(stage: "current_location"))
                    state.errorMessage = message
                }
            }

        case .mapViewportChanged(let center, let isUserInitiated):
            guard isUserInitiated else { return .none }
            switch state.route {
            case .registration:
                state.map.isCurrentLocationActive = false
                guard state.map.selectionTarget != nil else { return .none }
                state.map.candidateCoordinate = center
            case .pinEditing:
                guard var pinEdit = state.pinEdit, pinEdit.temporaryPlace == nil else { return .none }
                pinEdit.isCurrentLocationActive = false
                pinEdit.candidateCoordinate = center
                pinEdit.candidateAddress = nil
                state.pinEdit = pinEdit
                return .none
            default:
                break
            }

        case .placeSelectionTapped:
            guard state.route == .registration,
                  let target = state.map.selectionTarget,
                  let coordinate = state.map.candidateCoordinate,
                  !state.map.isAddressResolving
            else {
                return .none
            }
            state.map.addressRequestRevision += 1
            state.map.isAddressResolving = true
            let request = CourseRegistrationAddressRequest(
                revision: state.map.addressRequestRevision,
                target: target,
                coordinate: coordinate
            )
            return reverseGeocode(request)

        case .reverseGeocodingFinished(let request, let result):
            guard state.route == .registration,
                  request.revision == state.map.addressRequestRevision,
                  request.target == state.map.selectionTarget
            else {
                return .none
            }
            state.map.isAddressResolving = false
            switch result {
            case .success(let address):
                state.selectedPlaces[request.target] = .init(name: address, coordinate: request.coordinate)
                state.map.hasSelectedCurrentTarget = true
                RodiAnalytics.track(
                    .courseRegistrationPointSelected(
                        inputType: request.target.analyticsInputType,
                        source: "map"
                    )
                )
            case .failure(let error):
                state.errorMessage = error.userMessage
            }

        case .selectionCompletionTapped:
            guard state.route == .registration,
                  let target = state.map.selectionTarget,
                  state.map.hasSelectedCurrentTarget,
                  !state.map.isAddressResolving
            else {
                return .none
            }
            switch target {
            case .start:
                beginSelection(.destination, cameraTarget: state.selectedPlaces[.start]?.coordinate, state: &state)
            case .destination, .waypoint:
                state.map.selectionTarget = nil
                state.map.candidateCoordinate = nil
                state.map.hasSelectedCurrentTarget = false
                let points = routePoints(state: state)
                guard points.count >= 2 else { return .none }
                state.isRouteLoading = true
                state.routeRequestRevision += 1
                let revision = state.routeRequestRevision
                return requestInitialRoute(points: points, revision: revision)
            }

        case .registrationCompletionTapped:
            guard state.route == .registration,
                  state.map.selectionTarget == nil,
                  state.selectedPlaces[.start] != nil,
                  state.selectedPlaces[.destination] != nil,
                  !state.isRouteLoading,
                  state.routePath.count >= 2
            else {
                if state.route == .registration, !state.isRouteLoading {
                    state.errorMessage = "도로 경로를 불러오지 못했어요. 잠시 후 다시 시도해주세요."
                }
                return .none
            }
            state.route = .details
            state.detailsDraft = .init()
            RodiAnalytics.track(.courseRegistrationDetailsOpened)
            return loadRegistrationForm(state: &state)

        case .registrationFormLoaded(let revision, let result):
            guard state.route == .details, state.detailsLoadRevision == revision else { return .none }
            switch result {
            case .success(let form):
                state.detailsLoadState = .loaded(form)
            case .failure:
                state.detailsLoadState = .failed
            }

        case .registrationFormRetryTapped:
            guard state.route == .details, !state.isSubmittingCourse else { return .none }
            return loadRegistrationForm(state: &state)

        case .detailsCategoryTapped(let categoryCode):
            guard case let .loaded(form) = state.detailsLoadState,
                  let category = form.practiceType.categories.first(where: { $0.code == categoryCode })
            else { return .none }
            if state.detailsDraft.selectedCategoryCodes.contains(category.code) {
                state.detailsDraft.selectedCategoryCodes.remove(category.code)
                // 첫 카테고리(기초 주행)는 선택 여부와 무관하게 항상 표시되는 기본 연습유형이다.
                // 따라서 이 카테고리의 연습유형 선택값은 카테고리를 해제해도 유지한다.
                if form.practiceType.categories.first?.code != category.code {
                    let categoryTypeCodes = Set(category.practiceTypes.map(\.code))
                    state.detailsDraft.selectedPracticeTypeCodes.removeAll { categoryTypeCodes.contains($0) }
                }
            } else {
                state.detailsDraft.selectedCategoryCodes.insert(category.code)
            }

        case .detailsPracticeTypeTapped(let practiceTypeCode):
            guard case let .loaded(form) = state.detailsLoadState,
                  let category = form.practiceType.categories.first(where: {
                      $0.practiceTypes.contains(where: { $0.code == practiceTypeCode })
                  })
            else { return .none }
            let isDefaultCategory = form.practiceType.categories.first?.code == category.code
            guard isDefaultCategory || state.detailsDraft.selectedCategoryCodes.contains(category.code) else {
                return .none
            }
            if let index = state.detailsDraft.selectedPracticeTypeCodes.firstIndex(of: practiceTypeCode) {
                state.detailsDraft.selectedPracticeTypeCodes.remove(at: index)
            } else if state.detailsDraft.selectedPracticeTypeCodes.count < form.practiceType.maxSelect {
                state.detailsDraft.selectedPracticeTypeCodes.append(practiceTypeCode)
            } else {
                showAlert(form.practiceType.maxSelectExceededMessage, state: &state)
            }

        case .detailsCautionChanged(let value):
            state.detailsDraft.caution = String(value.prefix(CourseRegistrationTextLimit.caution))

        case .detailsDescriptionChanged(let value):
            state.detailsDraft.description = String(value.prefix(CourseRegistrationTextLimit.description))

        case .detailsBackTapped:
            guard state.route == .details, !state.isSubmittingCourse else { return .none }
            if state.detailsDraft.isDirty {
                state.isDetailsDiscardConfirmationPresented = true
            } else {
                leaveDetails(state: &state)
            }

        case .detailsDiscardConfirmed:
            guard state.isDetailsDiscardConfirmationPresented else { return .none }
            state.isDetailsDiscardConfirmationPresented = false
            leaveDetails(state: &state)

        case .detailsDiscardCancelled:
            state.isDetailsDiscardConfirmationPresented = false

        case .detailsSubmitTapped:
            guard state.route == .details,
                  !state.isSubmittingCourse,
                  case let .loaded(form) = state.detailsLoadState
            else { return .none }
            guard detailsCanSubmit(form: form, draft: state.detailsDraft),
                  detailsInputIsLongEnough(form: form, draft: state.detailsDraft, state: &state),
                  let submission = courseSubmission(state: state)
            else { return .none }
            state.isSubmittingCourse = true
            RodiAnalytics.track(
                .courseRegistrationSubmitted(
                    waypointCount: state.waypoints.count,
                    practiceTypeCount: state.detailsDraft.selectedPracticeTypeCodes.count,
                    hasCaution: !state.detailsDraft.caution.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            )
            return .run { send in
                do {
                    await send(.courseRegistrationFinished(.success(try await courseRepository.register(submission))))
                } catch let error as NetworkError {
                    await send(.courseRegistrationFinished(.failure(error)))
                } catch {
                    await send(.courseRegistrationFinished(.failure(.unknown(errorCode: "unknown"))))
                }
            }

        case .courseRegistrationFinished(let result):
            guard state.route == .details, state.isSubmittingCourse else { return .none }
            state.isSubmittingCourse = false
            switch result {
            case .success:
                state.isCourseRegistrationCompletionPresented = true
                RodiAnalytics.track(.courseRegistrationCompleted(waypointCount: state.waypoints.count))
            case .failure:
                RodiAnalytics.track(.courseRegistrationFailed(stage: "submission"))
                showAlert("코스를 등록하지 못했어요. 잠시 후 다시 시도해주세요.", state: &state)
            }

        case .courseRegistrationCompletionConfirmed:
            guard state.isCourseRegistrationCompletionPresented else { return .none }
            state.isCourseRegistrationCompletionPresented = false
            state.courseRegistrationCompletionRevision += 1

        case .alertToastDismissed(let revision):
            guard state.alertToastRevision == revision else { return .none }
            state.alertToast = nil

        case .initialRouteFinished(let revision, let result):
            guard state.route == .registration,
                  state.routeRequestRevision == revision,
                  state.isRouteLoading
            else {
                return .none
            }
            state.isRouteLoading = false
            switch result {
            case .success(let path):
                state.routePath = path
                RodiAnalytics.track(.courseRegistrationRoutePrepared(waypointCount: state.waypoints.count))
            case .failure:
                RodiAnalytics.track(.courseRegistrationFailed(stage: "route"))
                state.errorMessage = "도로 경로를 불러오지 못했어요. 잠시 후 다시 시도해주세요."
            }

        case .inputTargetTapped(let target):
            guard state.route == .registration, !state.map.isAddressResolving else { return .none }
            state.route = .registrationSearch(target)

        case .registrationSearchDismissed:
            guard case .registrationSearch = state.route else { return .none }
            state.route = .registration

        case .registrationSearchResultSelected(let result):
            guard case let .registrationSearch(target) = state.route,
                  let coordinate = result.coordinate
            else {
                state.errorMessage = "선택한 장소의 위치를 불러오지 못했어요."
                return .none
            }
            // 검색 화면을 여는 동안 시작된 현재 위치 조회가 늦게 끝나도,
            // 선택한 검색 결과의 카메라 이동을 다시 덮어쓰지 않게 한다.
            state.map.locationRequestRevision += 1
            state.route = .registration
            beginSelection(target, cameraTarget: coordinate, state: &state)
            state.map.candidateCoordinate = coordinate
            state.selectedPlaces[target] = .init(
                name: result.address.isEmpty ? result.title : result.address,
                coordinate: coordinate
            )
            state.map.hasSelectedCurrentTarget = true
            state.map.isCurrentLocationActive = false
            state.routePath = []
            RodiAnalytics.track(
                .courseRegistrationPointSelected(
                    inputType: target.analyticsInputType,
                    source: "search"
                )
            )

        case .routePointTapped(let pointID):
            let targets = orderedTargets(state: state)
            guard state.route == .registration,
                  targets.indices.contains(pointID)
            else {
                return .none
            }
            let target = targets[pointID]
            guard target != state.map.selectionTarget,
                  let original = state.selectedPlaces[target]
            else {
                return .none
            }
            state.pinEdit = .init(target: target, originalPlace: original)
            state.route = .pinEditing

        case .pinEditAddressTapped:
            guard state.route == .pinEditing, state.pinEdit != nil else { return .none }
            state.route = .pinEditSearch

        case .pinEditSearchDismissed:
            guard state.route == .pinEditSearch else { return .none }
            state.route = .pinEditing

        case .pinEditSearchResultSelected(let result):
            guard state.route == .pinEditSearch,
                  let coordinate = result.coordinate,
                  var pinEdit = state.pinEdit
            else {
                state.errorMessage = "선택한 장소의 위치를 불러오지 못했어요."
                return .none
            }
            pinEdit.cameraTarget = coordinate
            pinEdit.cameraRequestID += 1
            pinEdit.candidateCoordinate = coordinate
            pinEdit.candidateAddress = nil
            pinEdit.isCurrentLocationActive = false
            state.pinEdit = pinEdit
            state.route = .pinEditing
            return requestPinEditCandidateAddress(coordinate, state: &state)

        case .pinEditCandidateAddressFinished(let request, let result):
            guard state.route == .pinEditing,
                  var pinEdit = state.pinEdit,
                  request.revision == pinEdit.addressRequestRevision,
                  pinEdit.temporaryPlace == nil
            else {
                return .none
            }
            pinEdit.isAddressResolving = false
            switch result {
            case .success(let address):
                pinEdit.candidateCoordinate = request.coordinate
                pinEdit.candidateAddress = address
                pinEdit.temporaryPlace = .init(name: address, coordinate: request.coordinate)
                state.pinEdit = pinEdit
            case .failure(let error):
                state.pinEdit = pinEdit
                state.errorMessage = error.userMessage
            }

        case .pinEditSelectionTapped:
            guard state.route == .pinEditing,
                  var pinEdit = state.pinEdit,
                  let coordinate = pinEdit.candidateCoordinate,
                  !pinEdit.isAddressResolving,
                  pinEdit.temporaryPlace == nil
            else {
                return .none
            }
            state.pinEdit = pinEdit
            return requestPinEditCandidateAddress(coordinate, state: &state)

        case .pinEditRetryTapped:
            guard state.route == .pinEditing,
                  var pinEdit = state.pinEdit,
                  let temporary = pinEdit.temporaryPlace
            else {
                return .none
            }
            pinEdit.temporaryPlace = nil
            pinEdit.cameraTarget = temporary.coordinate
            pinEdit.cameraRequestID += 1
            pinEdit.candidateCoordinate = nil
            pinEdit.candidateAddress = nil
            state.pinEdit = pinEdit

        case .pinEditBackTapped:
            guard state.route == .pinEditing || state.route == .pinEditSearch else { return .none }
            state.pinEdit = nil
            state.route = .registration

        case .pinEditCompletionTapped:
            guard state.route == .pinEditing,
                  var pinEdit = state.pinEdit,
                  !pinEdit.isSaving
            else {
                return .none
            }
            guard let temporary = pinEdit.temporaryPlace else {
                state.pinEdit = nil
                state.route = .registration
                return .none
            }

            let points = routePoints(state: state, replacing: (pinEdit.target, temporary))
            guard points.count >= 2 else {
                state.selectedPlaces[pinEdit.target] = temporary
                state.pinEdit = nil
                state.route = .registration
                return .none
            }
            pinEdit.isSaving = true
            pinEdit.completionRevision += 1
            let revision = pinEdit.completionRevision
            state.pinEdit = pinEdit
            return .run { send in
                do {
                    let path = try await directionsService.fetchRoute(points: points)
                    await send(.pinEditRouteFinished(revision, .success(path)))
                } catch let error as KakaoDirectionsError {
                    await send(.pinEditRouteFinished(revision, .failure(error)))
                } catch {
                    await send(.pinEditRouteFinished(revision, .failure(.networkFailed("unknown"))))
                }
            }

        case .pinEditRouteFinished(let revision, let result):
            guard state.route == .pinEditing,
                  var pinEdit = state.pinEdit,
                  pinEdit.completionRevision == revision,
                  pinEdit.isSaving
            else {
                return .none
            }
            pinEdit.isSaving = false
            switch result {
            case .success(let path):
                guard let temporary = pinEdit.temporaryPlace else { return .none }
                state.selectedPlaces[pinEdit.target] = temporary
                state.routePath = path
                state.pinEdit = nil
                state.route = .registration
            case .failure:
                state.pinEdit = pinEdit
                state.errorMessage = "핀 위치를 수정하지 못했어요. 잠시 후 다시 시도해주세요."
            }
        }
        return .none
    }

    private func beginSelection(
        _ target: CourseRegistrationInputTarget,
        cameraTarget: RodiCoordinate? = nil,
        state: inout State
    ) {
        state.map.selectionTarget = target
        state.map.candidateCoordinate = nil
        state.map.hasSelectedCurrentTarget = false
        state.map.isAddressResolving = false
        if let cameraTarget {
            state.map.cameraTarget = cameraTarget
            state.map.cameraRequestID += 1
        }
    }

    private func orderedTargets(state: State) -> [CourseRegistrationInputTarget] {
        var targets: [CourseRegistrationInputTarget] = []
        if state.selectedPlaces[.start] != nil { targets.append(.start) }
        targets += state.waypoints.compactMap { waypoint in
            state.selectedPlaces[.waypoint(waypoint.id)] == nil ? nil : .waypoint(waypoint.id)
        }
        if state.selectedPlaces[.destination] != nil { targets.append(.destination) }
        return targets
    }

    private func routePoints(
        state: State,
        replacing replacement: (CourseRegistrationInputTarget, CourseRegistrationSelectedPlace)? = nil
    ) -> [RodiRouteOverlayPoint] {
        orderedTargets(state: state).enumerated().compactMap { index, target in
            let place = replacement?.0 == target ? replacement?.1 : state.selectedPlaces[target]
            guard let place else { return nil }
            return .init(
                id: index,
                sequence: index,
                role: target.routePointRole,
                name: place.name,
                coordinate: place.coordinate
            )
        }
    }

    private func requestCurrentLocation(_ request: CourseRegistrationLocationRequest) -> Effect<Action> {
        .run { send in
            let result = await mapService.requestCurrentLocation()
            await send(.currentLocationResolved(request, result))
        }
    }

    private func currentLocationFailureMessage(
        for result: CourseRegistrationMapService.CurrentLocationResult
    ) -> String? {
        switch result {
        case .resolved:
            nil
        case .permissionDenied:
            "현재 위치를 확인할 수 없어요. 위치 권한을 허용한 뒤 다시 시도해주세요."
        case .unavailable:
            "현재 위치를 확인할 수 없어요. 위치 서비스와 네트워크 상태를 확인한 뒤 다시 시도해주세요."
        }
    }

    private func reverseGeocode(_ request: CourseRegistrationAddressRequest) -> Effect<Action> {
        .run { send in
            do {
                await send(.reverseGeocodingFinished(request, .success(try await mapService.reverseGeocode(request.coordinate))))
            } catch let error as CourseRegistrationAddressLookupError {
                await send(.reverseGeocodingFinished(request, .failure(error)))
            } catch {
                await send(.reverseGeocodingFinished(request, .failure(.networkFailed)))
            }
        }
    }

    private func requestInitialRoute(
        points: [RodiRouteOverlayPoint],
        revision: Int
    ) -> Effect<Action> {
        .run { send in
            do {
                await send(.initialRouteFinished(revision, .success(try await directionsService.fetchRoute(points: points))))
            } catch let error as KakaoDirectionsError {
                await send(.initialRouteFinished(revision, .failure(error)))
            } catch {
                await send(.initialRouteFinished(revision, .failure(.networkFailed("unknown"))))
            }
        }
    }

    private func requestPinEditCandidateAddress(
        _ coordinate: RodiCoordinate,
        state: inout State
    ) -> Effect<Action> {
        guard var pinEdit = state.pinEdit else { return .none }
        pinEdit.addressRequestRevision += 1
        pinEdit.isAddressResolving = true
        state.pinEdit = pinEdit
        let request = CourseRegistrationPinEditAddressRequest(
            revision: pinEdit.addressRequestRevision,
            coordinate: coordinate
        )
        return .run { send in
            do {
                await send(.pinEditCandidateAddressFinished(request, .success(try await mapService.reverseGeocode(coordinate))))
            } catch let error as CourseRegistrationAddressLookupError {
                await send(.pinEditCandidateAddressFinished(request, .failure(error)))
            } catch {
                await send(.pinEditCandidateAddressFinished(request, .failure(.networkFailed)))
            }
        }
    }

    private func loadRegistrationForm(state: inout State) -> Effect<Action> {
        state.detailsLoadRevision += 1
        let revision = state.detailsLoadRevision
        state.detailsLoadState = .loading
        return .run { send in
            do {
                await send(.registrationFormLoaded(revision, .success(try await courseRepository.fetchRegistrationForm())))
            } catch let error as NetworkError {
                await send(.registrationFormLoaded(revision, .failure(error)))
            } catch {
                await send(.registrationFormLoaded(revision, .failure(.unknown(errorCode: "unknown"))))
            }
        }
    }

    private func leaveDetails(state: inout State) {
        state.detailsLoadState = .idle
        state.detailsDraft = .init()
        state.route = .registration
    }

    private func registrationHasInput(_ state: State) -> Bool {
        !state.waypoints.isEmpty
            || !state.selectedPlaces.isEmpty
            || !state.routePath.isEmpty
    }

    private func resetRegistrationState(state: inout State) {
        state.waypoints = []
        state.selectedPlaces = [:]
        state.routePath = []
        state.isRouteLoading = false
        state.map = .init()
        state.pinEdit = nil
        state.detailsLoadState = .idle
        state.detailsDraft = .init()
        state.isDetailsDiscardConfirmationPresented = false
        state.isSubmittingCourse = false
        state.isCourseRegistrationCompletionPresented = false
    }

    private func detailsInputIsLongEnough(
        form: CourseRegistrationForm,
        draft: CourseRegistrationDetailsDraft,
        state: inout State
    ) -> Bool {
        let inputs: [(String, CourseRegistrationTextInputSpec, String, Int)] = [
            (form.sections.caution, form.inputs.caution, draft.caution, 0),
            (form.sections.description, form.inputs.description, draft.description, 10)
        ]
        for (title, spec, value, requiredMinimumLength) in inputs {
            let count = value.trimmedForCourseRegistration.count
            if spec.required, count == 0 {
                showAlert("\(title)을 입력해 주세요.", state: &state)
                return false
            }
            let minLength = max(spec.minLength ?? 0, requiredMinimumLength)
            if count > 0, count < minLength {
                if title == form.sections.description {
                    showAlert("한줄 설명은 \(minLength)자 이상이어야 해요.", state: &state)
                } else {
                    showAlert("\(title)은 \(minLength)자 이상이어야 해요.", state: &state)
                }
                return false
            }
        }
        return true
    }

    private func detailsCanSubmit(
        form: CourseRegistrationForm,
        draft: CourseRegistrationDetailsDraft
    ) -> Bool {
        guard !draft.selectedCategoryCodes.isEmpty, !draft.selectedPracticeTypeCodes.isEmpty else {
            return false
        }
        let values: [(CourseRegistrationTextInputSpec, String)] = [
            (form.inputs.caution, draft.caution),
            (form.inputs.description, draft.description)
        ]
        let hasRequiredInputs = values.allSatisfy { spec, value in
            !spec.required || !value.trimmedForCourseRegistration.isEmpty
        }
        return hasRequiredInputs && draft.description.trimmedForCourseRegistration.count >= 10
    }

    private func courseSubmission(state: State) -> CourseRegistrationSubmission? {
        guard let start = state.selectedPlaces[.start],
              let destination = state.selectedPlaces[.destination],
              state.routePath.count >= 2
        else {
            return nil
        }

        var waypoints: [CourseRegistrationSubmissionWaypoint] = [
            .init(
                kind: .start,
                latitude: start.coordinate.latitude,
                longitude: start.coordinate.longitude,
                name: start.name
            )
        ]
        for waypoint in state.waypoints {
            guard let place = state.selectedPlaces[.waypoint(waypoint.id)] else { continue }
            waypoints.append(.init(
                kind: .via,
                latitude: place.coordinate.latitude,
                longitude: place.coordinate.longitude,
                name: place.name
            ))
        }
        waypoints.append(.init(
            kind: .destination,
            latitude: destination.coordinate.latitude,
            longitude: destination.coordinate.longitude,
            name: destination.name
        ))

        let distanceMeters = CourseRegistrationRouteDistanceCalculator.meters(for: state.routePath)
        guard distanceMeters > 0 else { return nil }
        return .init(
            name: start.name,
            address: start.name,
            distanceMeters: distanceMeters,
            waypoints: waypoints,
            practiceTypes: state.detailsDraft.selectedPracticeTypeCodes,
            description: state.detailsDraft.description.trimmedForCourseRegistration,
            caution: state.detailsDraft.caution.trimmedForCourseRegistration
        )
    }

    private func showAlert(_ message: String, state: inout State) {
        state.alertToastRevision += 1
        let revision = state.alertToastRevision
        state.alertToast = .init(message: message, revision: revision)
    }
}

private enum CourseRegistrationRouteDistanceCalculator {
    static func meters(for path: [RodiCoordinate]) -> Int {
        guard path.count >= 2 else { return 0 }
        let distance = zip(path, path.dropFirst()).reduce(0.0) { partial, pair in
            partial + CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
                .distance(from: CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude))
        }
        return max(0, Int(distance.rounded()))
    }
}

private enum CourseRegistrationTextLimit {
    static let caution = 100
    static let description = 30
}

private extension String {
    var trimmedForCourseRegistration: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum CourseRegistrationDetailsLoadState: Equatable {
    case idle
    case loading
    case loaded(CourseRegistrationForm)
    case failed
}

struct CourseRegistrationDetailsDraft: Equatable {
    var selectedCategoryCodes: Set<String> = []
    var selectedPracticeTypeCodes: [String] = []
    var caution = ""
    var description = ""

    var isDirty: Bool {
        !selectedCategoryCodes.isEmpty
            || !selectedPracticeTypeCodes.isEmpty
            || !caution.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct CourseRegistrationAlertToastState: Equatable {
    let message: String
    let revision: Int
}

struct CourseRegistrationWaypoint: Equatable, Identifiable {
    let id: UUID

    init(id: UUID = UUID()) {
        self.id = id
    }
}

enum CourseRegistrationInputTarget: Hashable {
    case start
    case destination
    case waypoint(UUID)

    var selectionTitle: String {
        switch self {
        case .start: "출발지 선택"
        case .destination: "도착지 선택"
        case .waypoint: "경유지 선택"
        }
    }

    var movingPinAssetName: String {
        switch self {
        case .start: "ic_start_pin"
        case .destination: "ic_arrival_pin"
        case .waypoint: "ic_route_waypoint"
        }
    }

    var inputIconName: String {
        switch self {
        case .start: "ic_course_start"
        case .destination: "ic_course_destination"
        case .waypoint: "ic_course_waypoint"
        }
    }

    var routePointRole: RodiCoursePointRole {
        switch self {
        case .start: .start
        case .destination: .end
        case .waypoint: .waypoint
        }
    }
}

private extension CourseRegistrationInputTarget {
    var analyticsInputType: String {
        switch self {
        case .start: "start"
        case .destination: "destination"
        case .waypoint: "waypoint"
        }
    }
}

struct CourseRegistrationSelectedPlace: Equatable {
    let name: String
    let coordinate: RodiCoordinate
}

struct CourseRegistrationMapState: Equatable {
    var selectionTarget: CourseRegistrationInputTarget?
    var cameraTarget: RodiCoordinate = .seoulCityHall
    var cameraRequestID = 0
    var locationRequestRevision = 0
    var hasRequestedInitialLocation = false
    var addressRequestRevision = 0
    var candidateCoordinate: RodiCoordinate?
    var hasSelectedCurrentTarget = false
    var isAddressResolving = false
    var isCurrentLocationActive = false
}

struct CourseRegistrationPinEditState: Equatable {
    let target: CourseRegistrationInputTarget
    let originalPlace: CourseRegistrationSelectedPlace
    var cameraTarget: RodiCoordinate
    var cameraRequestID = 0
    var locationRequestRevision = 0
    var addressRequestRevision = 0
    var completionRevision = 0
    var candidateCoordinate: RodiCoordinate?
    var candidateAddress: String?
    var temporaryPlace: CourseRegistrationSelectedPlace?
    var isAddressResolving = false
    var isCurrentLocationActive = false
    var isSaving = false

    init(target: CourseRegistrationInputTarget, originalPlace: CourseRegistrationSelectedPlace) {
        self.target = target
        self.originalPlace = originalPlace
        cameraTarget = originalPlace.coordinate
        candidateCoordinate = nil
        candidateAddress = nil
    }
}

struct CourseRegistrationLocationRequest: Equatable {
    enum Scope: Equatable { case registration, pinEditing }
    enum Source: Equatable { case initial, userAction }

    let revision: Int
    let scope: Scope
    let source: Source
}

struct CourseRegistrationAddressRequest: Equatable {
    let revision: Int
    let target: CourseRegistrationInputTarget
    let coordinate: RodiCoordinate
}

struct CourseRegistrationPinEditAddressRequest: Equatable {
    let revision: Int
    let coordinate: RodiCoordinate
}

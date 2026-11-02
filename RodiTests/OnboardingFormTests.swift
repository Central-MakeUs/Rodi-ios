import XCTest
@testable import Rodi

/// 실제 인증 응답이 아닌, 공개 Prod schema 기반 합성 입력입니다.
@MainActor
final class OnboardingFormTests: XCTestCase {
    func testProdSchemaMapsSortedStepsAndStableCodes() throws {
        let form = try makeForm()
        XCTAssertEqual(form.steps.map(\.isExperience), [true, false])
        XCTAssertEqual(form.steps[0].questions.first?.id, .drivingPeriod)
        XCTAssertEqual(form.steps[0].questions.first?.options.first?.id, "UNDER_1_MONTH")
        XCTAssertTrue(form.steps[1].skippable)
    }

    func testDevSchemaMissingRulesDoesNotUseProdDefaults() throws {
        var object = try fixture()
        var steps = object["steps"] as! [[String: Any]]
        steps[0].removeValue(forKey: "skippable")
        object["steps"] = steps
        XCTAssertThrowsError(try map(object))
    }

    func testMissingRankedLimitIsRejected() throws {
        var object = try fixture()
        var steps = object["steps"] as! [[String: Any]]
        var questions = steps[0]["questions"] as! [[String: Any]]
        questions[0].removeValue(forKey: "maxSelect")
        steps[0]["questions"] = questions
        object["steps"] = steps
        XCTAssertThrowsError(try map(object))
    }

    func testUnknownFieldAndOptionAreRejected() throws {
        for changeOption in [false, true] {
            var object = try fixture()
            var steps = object["steps"] as! [[String: Any]]
            var questions = steps[1]["questions"] as! [[String: Any]]
            if changeOption { questions[0]["options"] = [["code": "UNKNOWN", "label": "새 선택지", "order": 1]] }
            else { questions[0]["code"] = "unknownQuestion" }
            steps[1]["questions"] = questions
            object["steps"] = steps
            XCTAssertThrowsError(try map(object))
        }
    }

    func testConditionalRequiredAnswersAreRemovedAndExcludedFromSubmission() throws {
        let form = try makeForm()
        let input: [MemberOnboardingForm.Field: [String]] = [
            .drivingPeriod: ["UNDER_1_MONTH"], .roadExperiences: ["NONE"],
            .soloDrivingRange: ["HIGHWAY_LONG"], .soloParkingLevel: ["MOSTLY_POSSIBLE"]
        ]
        let values = OnboardingFormAnswerAdapter.sanitized(input, form: form)
        XCTAssertNil(values[.soloDrivingRange])
        XCTAssertTrue(form.canProceed(in: form.steps[0], answers: values))
        var experience = OnboardingDrivingExperience()
        var preferences = OnboardingDrivingPreferences()
        var goal = ""
        OnboardingFormAnswerAdapter.apply(values, experience: &experience, preferences: &preferences, goal: &goal)
        let submission = try XCTUnwrap(OnboardingSubmissionMapper.make(drivingExperience: experience, preferences: preferences, drivingGoal: goal))
        XCTAssertNil(submission.soloDrivingRange)
        XCTAssertNil(submission.soloParkingLevel)
    }

    func testSkipFollowUpsClearsLaterAnswers() throws {
        let form = try makeForm()
        let values = OnboardingFormAnswerAdapter.sanitized([
            .drivingPeriod: ["OVER_10_YEARS"], .roadExperiences: ["SOLO"], .soloDrivingRange: ["NEAR_HOME"]
        ], form: form)
        XCTAssertNil(values[.roadExperiences])
        XCTAssertEqual(form.visibleQuestions(in: form.steps[0], answers: values).map(\.id), [.drivingPeriod])
    }

    func testExclusiveSelectionAndRankLimitPreserveOrder() throws {
        let reducer = OnboardingProfileReducer(memberRepository: OnboardingMemberStub())
        var session = OnboardingSession()
        session.form = try makeForm()
        var state = OnboardingProfileReducer.State(session: session, screen: .drivingExperience)
        _ = reducer.reduce(&state, with: .selectFormOption(.drivingPeriod, "UNDER_1_MONTH"))
        _ = reducer.reduce(&state, with: .selectFormOption(.roadExperiences, "SOLO"))
        _ = reducer.reduce(&state, with: .selectFormOption(.roadExperiences, "NONE"))
        XCTAssertEqual(state.formAnswers[.roadExperiences], ["NONE"])
        _ = reducer.reduce(&state, with: .selectFormOption(.roadExperiences, "SOLO"))
        XCTAssertEqual(state.formAnswers[.roadExperiences], ["SOLO"])
        state.screen = .drivingPreference
        for code in ["PARKING", "U_TURN", "LANE_CHANGE"] {
            _ = reducer.reduce(&state, with: .selectFormOption(.practiceTypes, code))
        }
        XCTAssertEqual(state.formAnswers[.practiceTypes], ["PARKING", "U_TURN"])
    }

    func testTextLimitAndDraftBridge() throws {
        let reducer = OnboardingProfileReducer(memberRepository: OnboardingMemberStub())
        var session = OnboardingSession()
        session.form = try makeForm()
        var state = OnboardingProfileReducer.State(session: session, screen: .drivingPreference)
        _ = reducer.reduce(&state, with: .drivingGoalChanged(String(repeating: "가", count: 31)))
        XCTAssertEqual(state.drivingGoal.count, 30)
        let values = OnboardingFormAnswerAdapter.values(experience: .init(licenseDrivingPeriod: .oneToTwoYears), preferences: .init(selectedPracticeSituations: [.parking, .uTurn], vehicleType: .suv), goal: state.drivingGoal)
        var experience = OnboardingDrivingExperience()
        var preferences = OnboardingDrivingPreferences()
        var goal = ""
        OnboardingFormAnswerAdapter.apply(values, experience: &experience, preferences: &preferences, goal: &goal)
        XCTAssertEqual(experience.licenseDrivingPeriod, .oneToTwoYears)
        XCTAssertEqual(preferences.selectedPracticeSituations, [.parking, .uTurn])
        XCTAssertEqual(preferences.vehicleType, .suv)
    }

    func testFailureRetryAndStaleResponseAreGuarded() throws {
        let reducer = OnboardingProfileReducer(memberRepository: OnboardingMemberStub())
        var state = OnboardingProfileReducer.State(session: .init(), screen: .drivingExperience)
        _ = reducer.reduce(&state, with: .appeared)
        let firstID = state.requestID
        _ = reducer.reduce(&state, with: .appeared)
        XCTAssertEqual(state.requestID, firstID)
        _ = reducer.reduce(&state, with: .formLoaded(.failure(.networkUnavailable), requestID: firstID))
        guard case .failed = state.formLoadState else { return XCTFail("실패 상태 필요") }
        _ = reducer.reduce(&state, with: .retryFormTapped)
        _ = reducer.reduce(&state, with: .formLoaded(.success(try makeForm()), requestID: firstID))
        XCTAssertNil(state.session.form)
        _ = reducer.reduce(&state, with: .disappeared)
        _ = reducer.reduce(&state, with: .formLoaded(.success(try makeForm()), requestID: state.requestID - 1))
        XCTAssertNil(state.session.form)
    }

    func testNicknameGuestAndCachedFormDoNotFetchAgain() throws {
        let reducer = OnboardingProfileReducer(memberRepository: OnboardingMemberStub())
        for screen in [OnboardingProfileReducer.State.Screen.nickname, .drivingExperience] {
            var session = OnboardingSession()
            if screen == .drivingExperience { session.mode = .guest }
            var state = OnboardingProfileReducer.State(session: session, screen: screen)
            _ = reducer.reduce(&state, with: .appeared)
            XCTAssertEqual(state.requestID, 0)
        }
        var session = OnboardingSession()
        session.form = try makeForm()
        var state = OnboardingProfileReducer.State(session: session, screen: .drivingPreference)
        _ = reducer.reduce(&state, with: .appeared)
        XCTAssertEqual(state.requestID, 0)
    }

    func testSkipClearsOptionalDraftAndPreventsDuplicateSubmission() throws {
        let reducer = OnboardingProfileReducer(memberRepository: OnboardingMemberStub())
        var session = OnboardingSession()
        session.form = try makeForm()
        session.drivingExperience = .init(licenseDrivingPeriod: .overTenYears)
        session.preferences = .init(selectedPracticeSituations: [.parking], vehicleType: .suv)
        session.drivingGoal = "초안"
        var state = OnboardingProfileReducer.State(session: session, screen: .drivingPreference)
        _ = reducer.reduce(&state, with: .preferenceSkipTapped)
        XCTAssertEqual(state.session.preferences?.selectedPracticeSituations, [])
        XCTAssertEqual(state.session.drivingGoal, "")
        let requestID = state.requestID
        _ = reducer.reduce(&state, with: .preferenceSkipTapped)
        XCTAssertEqual(state.requestID, requestID)
    }

    func testClientErrorDoesNotCompleteOnboarding() throws {
        let reducer = OnboardingProfileReducer(memberRepository: OnboardingMemberStub())
        var state = OnboardingProfileReducer.State(session: .init(), screen: .drivingPreference)
        _ = reducer.reduce(&state, with: .submissionCompleted(.failed("입력을 확인해주세요."), requestID: 0))
        XCTAssertEqual(state.presentation, .snackbar("입력을 확인해주세요."))
        XCTAssertNil(state.transition)
    }

    private func makeForm() throws -> MemberOnboardingForm { try map(fixture()) }
    private func map(_ object: [String: Any]) throws -> MemberOnboardingForm {
        let data = try JSONSerialization.data(withJSONObject: object)
        return try MemberOnboardingFormMapper.map(JSONDecoder().decode(MemberOnboardingFormResponseDTO.self, from: data))
    }

    private func fixture() throws -> [String: Any] {
        let text = #"""
        {"steps":[
          {"order":2,"skippable":true,"title":"추가 정보","questions":[
            {"code":"practiceTypes","order":6,"type":"RANKED_SELECT","required":false,"title":"연습유형","maxSelect":2,"options":[{"code":"PARKING","label":"주차","order":1},{"code":"U_TURN","label":"유턴","order":2},{"code":"LANE_CHANGE","label":"차선변경","order":3}]},
            {"code":"carType","order":7,"type":"SINGLE_SELECT","required":false,"title":"차종","options":[{"code":"SUV","label":"SUV","order":1}]},
            {"code":"drivingGoal","order":8,"type":"TEXT","required":false,"title":"운전 목표","placeholder":"목표","maxLength":30}
          ]},
          {"order":1,"skippable":false,"title":"운전 경험","questions":[
            {"code":"drivingPeriod","order":1,"type":"SINGLE_SELECT","required":true,"title":"운전 기간","options":[{"code":"OVER_10_YEARS","label":"10년 이상","order":2,"skipsFollowUps":true},{"code":"UNDER_1_MONTH","label":"1개월 미만","order":1}]},
            {"code":"recentFrequency","order":2,"type":"SINGLE_SELECT","required":false,"title":"운전 빈도","options":[{"code":"RARELY","label":"거의 없음","order":1}]},
            {"code":"roadExperiences","order":3,"type":"MULTI_SELECT","required":true,"title":"도로 경험","options":[{"code":"NONE","label":"없음","order":1,"exclusive":true},{"code":"SOLO","label":"혼자 연습","order":2}]},
            {"code":"soloDrivingRange","order":4,"type":"SINGLE_SELECT","required":true,"title":"운전 범위","showWhen":{"question":"roadExperiences","anyOf":["SOLO"]},"options":[{"code":"NEAR_HOME","label":"집 근처","order":1},{"code":"HIGHWAY_LONG","label":"장거리","order":2}]},
            {"code":"soloParkingLevel","order":5,"type":"SINGLE_SELECT","required":true,"title":"주차 수준","showWhen":{"question":"roadExperiences","anyOf":["SOLO"]},"options":[{"code":"MOSTLY_POSSIBLE","label":"대부분 가능","order":1}]}
          ]}
        ]}
        """#
        return try JSONSerialization.jsonObject(with: Data(text.utf8)) as! [String: Any]
    }
}

private struct OnboardingMemberStub: MemberRepository {
    func fetchOnboardingForm() async throws(NetworkError) -> MemberOnboardingForm { throw .networkUnavailable }
    func fetchMyProfile() async throws(NetworkError) -> MemberProfile { fatalError() }
    func withdraw() async throws(NetworkError) {}
    func hardWithdraw() async throws(NetworkError) {}
    func block(memberID: Int) async throws(NetworkError) {}
    func fetchBlockedMembers(query: BlockedMemberQuery) async throws(NetworkError) -> BlockedMemberPage { fatalError() }
    func unblock(memberID: Int) async throws(NetworkError) {}
    func updateDrivingGoal(_ drivingGoal: String) async throws(NetworkError) {}
    func updateNickname(_ nickname: String) async throws(NetworkError) -> String { nickname }
    func updatePlaceFilterTags(_ tags: [PlacePracticeType]) async throws(NetworkError) {}
    func submitOnboarding(_ submission: MemberOnboardingSubmission) async throws(NetworkError) {}
    func completeCourseTutorial() async throws(NetworkError) -> CourseTutorialCompletion { fatalError() }
}

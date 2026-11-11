import Foundation
import XCTest
@testable import Rodi

@MainActor
final class ReviewAndCourseReportDTOTests: XCTestCase {
    func testReviewWritingFormPreservesIssueConditionAndTextRules() throws {
        let json = """
        {
          "title": "후기 작성", "placeName": "테스트 코스",
          "steps": [{"order": 1, "questions": [
            {"code":"isRecommended","order":1,"type":"SINGLE_SELECT","required":true,"title":"추천 여부",
             "options":[{"code":"true","label":"추천해요","order":2,"requiresTextInput":false},
                        {"code":"false","label":"별로에요","order":1,"requiresTextInput":false}]},
            {"code":"difficulty","order":2,"type":"SINGLE_SELECT","required":true,"title":"난이도",
             "options":[{"code":"EASY","label":"쉬움","order":1,"requiresTextInput":false}]},
            {"code":"congestion","order":3,"type":"SINGLE_SELECT","required":true,"title":"혼잡도",
             "options":[{"code":"QUIET","label":"한산함","order":1,"requiresTextInput":false}]},
          {
            "code": "courseIssues", "order": 4, "type": "MULTI_SELECT", "required": true,
            "title": "코스 문제", "showWhen": {"question": "isRecommended", "anyOf": ["false"]},
            "options": [{"code": "OTHER", "label": "기타", "order": 1,
              "requiresTextInput": true, "textInputMaxLength": 30}]
          }]},
          {"order":2,"questions":[
            {"code":"practiceMethod","order":5,"type":"SINGLE_SELECT","required":true,"title":"연습 방법",
             "options":[{"code":"SOLO","label":"혼자 연습","order":1,"requiresTextInput":false}]}
          ]}]
        }
        """
        let form = try JSONDecoder().decode(ReviewWritingFormResponseDTO.self, from: Data(json.utf8))
        let question = try XCTUnwrap(form.steps.first?.questions.first { $0.code == "courseIssues" })
        XCTAssertEqual(question.code, "courseIssues")
        XCTAssertEqual(question.showWhen?.question, "isRecommended")
        XCTAssertEqual(question.showWhen?.anyOf, ["false"])
        XCTAssertEqual(question.options?.first?.textInputMaxLength, 30)
        let mapped = try ReviewMapper.writingForm(from: form)
        XCTAssertEqual(mapped[.isRecommended]?.options.map(\.code), ["false", "true"])
        XCTAssertEqual(mapped[.courseIssues]?.isVisible(for: false), true)
        XCTAssertEqual(mapped[.courseIssues]?.isVisible(for: true), false)
    }

    func testReviewRequestSupportsBothEvaluationBranchesWithoutExtraKeys() throws {
        let encoder = JSONEncoder()
        let recommended = ReviewRequestDTO(
            isRecommended: true, difficulty: "EASY", congestion: "QUIET",
            practiceMethod: "SOLO", content: nil, caution: nil,
            courseIssues: nil, courseIssueDetail: nil
        )
        let negative = ReviewRequestDTO(
            isRecommended: false, difficulty: nil, congestion: nil,
            practiceMethod: "SOLO", content: nil, caution: nil,
            courseIssues: ["OTHER"], courseIssueDetail: "테스트"
        )
        let recommendedBody = try jsonObject(from: encoder.encode(recommended))
        XCTAssertEqual(Set(recommendedBody.keys), ["isRecommended", "difficulty", "congestion", "practiceMethod"])
        let negativeBody = try jsonObject(from: encoder.encode(negative))
        XCTAssertEqual(Set(negativeBody.keys), ["isRecommended", "practiceMethod", "courseIssues", "courseIssueDetail"])
        XCTAssertEqual(negativeBody["courseIssues"] as? [String], ["OTHER"])
    }

    func testDetailDecodesDevNullEvaluationAndProdWithoutIssueFields() throws {
        let common = """
        "reviewId":1,"placeId":42,"placeName":"테스트 코스","practiceMethod":"SOLO",
        "isEditable":true,"isHidden":false,"isVerifiedVisit":true,"createdAt":"2026-11-11T00:00:00"
        """
        let dev = """
        {\(common),"isRecommended":false,"difficulty":null,"congestion":null,
         "courseIssues":["OTHER"],"courseIssueDetail":"테스트"}
        """
        let prod = """
        {\(common),"isRecommended":true,"difficulty":"EASY","congestion":"QUIET"}
        """
        let decoder = JSONDecoder()
        let devDetail = try decoder.decode(ReviewDetailResponseDTO.self, from: Data(dev.utf8))
        XCTAssertNil(devDetail.difficulty)
        XCTAssertNil(devDetail.congestion)
        XCTAssertEqual(devDetail.courseIssues, ["OTHER"])
        XCTAssertEqual(devDetail.courseIssueDetail, "테스트")
        XCTAssertEqual(try ReviewMapper.detail(from: devDetail).courseIssues, ["OTHER"])
        let prodDetail = try decoder.decode(ReviewDetailResponseDTO.self, from: Data(prod.utf8))
        XCTAssertEqual(prodDetail.difficulty, "EASY")
        XCTAssertNil(prodDetail.courseIssues)
    }

    private func jsonObject(from data: Data) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

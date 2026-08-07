//
//  SafetyAgreement.swift
//  Rodi
//

import Foundation

enum SafetyAgreement: String, CaseIterable, Identifiable {
    case license
    case learnerPermit
    case responsibility

    var id: String { rawValue }

    var text: String {
        switch self {
        case .license:
            "본인은 유효한 자동차 운전면허 (제1･2종 보통 이상)를 소지한 만 18세 이상임을 확인합니다."
        case .learnerPermit:
            "연습운전면허 소지자는 운전경력 2년 이상의 동승자와 함께 이용해야 함을 확인합니다."
        case .responsibility:
            "위 내용을 확인하고 동의합니다."
        }
    }
}

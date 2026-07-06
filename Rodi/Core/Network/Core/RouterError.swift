//
//  RouterError.swift
//  BoilerplateSwiftUI
//
//  Created by mac on 5/14/26.
//

import Foundation

public enum RouterError: Error {
    case urlFail(url: String = "")
    case decodingFail
    case encodingFail
    case retryFail
    case timeOut
    case unknown(errorCode: String)
    case cancel
    case errorModelDecodingFail
    case refreshFailGoRoot
}

extension RouterError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .urlFail(let url):
            return "유효하지 않은 URL입니다: \(url)"
        case .decodingFail:
            return "응답 디코딩에 실패했습니다."
        case .encodingFail:
            return "요청 인코딩에 실패했습니다."
        case .retryFail:
            return "재시도에 실패했습니다."
        case .timeOut:
            return "요청 시간이 초과되었습니다."
        case .unknown(let errorCode):
            return "알 수 없는 오류가 발생했습니다. (\(errorCode))"
        case .cancel:
            return "요청이 취소되었습니다."
        case .errorModelDecodingFail:
            return "에러 모델 디코딩에 실패했습니다."
        case .refreshFailGoRoot:
            return "인증 갱신에 실패했습니다."
        }
    }
}

//
//  NetworkError.swift
//  BoilerplateSwiftUI
//
//  Created by mac on 5/12/26.
//

import Foundation

public enum NetworkError: Error, Equatable {
    case urlFail(url: String = "")
    case decodingFail
    case encodingFail
    case retryFail
    case timeOut
    case networkUnavailable
    case httpStatusCode(Int)
    case apiError(code: String, message: String, httpStatusCode: Int? = nil)
    case unknown(errorCode: String)
    case cancel
    case errorModelDecodingFail
    case refreshFailGoRoot
}

extension NetworkError: LocalizedError {
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
        case .networkUnavailable:
            return "네트워크 연결을 확인해 주세요."
        case .httpStatusCode(let statusCode):
            return "서버 응답이 올바르지 않습니다. (HTTP \(statusCode))"
        case .apiError(_, let message, _):
            return message
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

extension NetworkError {
    init(_ routerError: RouterError) {
        switch routerError {
        case .urlFail(let url):
            self = .urlFail(url: url)
        case .decodingFail:
            self = .decodingFail
        case .encodingFail:
            self = .encodingFail
        case .retryFail:
            self = .retryFail
        case .timeOut:
            self = .timeOut
        case .unknown(let errorCode):
            self = .unknown(errorCode: errorCode)
        case .cancel:
            self = .cancel
        case .errorModelDecodingFail:
            self = .errorModelDecodingFail
        case .refreshFailGoRoot:
            self = .refreshFailGoRoot
        }
    }
}

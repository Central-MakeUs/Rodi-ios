//
//  KakaoRESTClient.swift
//  Rodi
//

import Foundation

/// Feature 전용 Kakao REST adapter가 공통으로 사용하는 인증·전송 경계다.
/// endpoint, query, DTO decoding, 사용자 문구는 각 feature service가 계속 소유한다.
struct KakaoRESTClient {
    struct Response {
        let data: Data
        let statusCode: Int
    }

    enum TransportError: Error {
        case missingAPIKey
        case invalidHTTPResponse
        case networkFailed
    }

    func get(url: URL) async throws -> Response {
        guard !KakaoConfiguration.restAPIKey.isEmpty else {
            throw TransportError.missingAPIKey
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("KakaoAK \(KakaoConfiguration.restAPIKey)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw TransportError.networkFailed
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TransportError.invalidHTTPResponse
        }

        return .init(data: data, statusCode: httpResponse.statusCode)
    }
}

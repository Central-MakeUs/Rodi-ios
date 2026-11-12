//
//  KakaoRESTClient.swift
//  Rodi
//

import Foundation

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

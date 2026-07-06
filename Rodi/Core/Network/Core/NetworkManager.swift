//
//  NetworkManager.swift
//  Rodi
//

import Alamofire
import Foundation

final class NetworkManager {
    private let authInterceptor: AuthInterceptor?

    init(authInterceptor: AuthInterceptor? = nil) {
        self.authInterceptor = authInterceptor
    }

    func request<T: Decodable, R: TargetType>(
        _ target: R,
        as dto: T.Type
    ) async throws(NetworkError) -> T {
        try await request(target, as: dto, allowsTokenRefresh: true)
    }
}

private extension NetworkManager {
    func request<T: Decodable, R: TargetType>(
        _ target: R,
        as dto: T.Type,
        allowsTokenRefresh: Bool
    ) async throws(NetworkError) -> T {
        let urlRequest = try makeRequest(for: target)
        RodiLogger.debug("Request: \(target.method.rawValue) \(target.path)")
        let response = await performRequest(dtoType: dto, request: urlRequest)

        do {
            let parsed = try parseResponse(response)
            RodiLogger.debug("Response success: \(target.method.rawValue) \(target.path) status=\(response.response?.statusCode ?? 0)")
            return parsed
        } catch let error {
            RodiLogger.warning("Response failure: \(target.method.rawValue) \(target.path) error=\(error)")
            guard target.requiresAuthentication,
                  allowsTokenRefresh,
                  shouldRefreshToken(for: error) else {
                throw error
            }

            guard let refreshedToken = try await authInterceptor?.refreshAccessToken(),
                  !refreshedToken.accessToken.isEmpty,
                  !refreshedToken.refreshToken.isEmpty else {
                RodiLogger.error("Token refresh failed")
                throw .refreshFailGoRoot
            }

            RodiLogger.info("Token refresh succeeded; retrying request: \(target.path)")
            return try await request(target, as: dto, allowsTokenRefresh: false)
        }
    }

    func shouldRefreshToken(for error: NetworkError) -> Bool {
        switch error {
        case .httpStatusCode(401):
            true
        case .apiError(let code, _):
            code == "AUTH_401_1" || code == "AUTH_401_6"
        default:
            false
        }
    }

    func makeRequest<R: TargetType>(for target: R) throws(NetworkError) -> URLRequest {
        do {
            let request = try target.asURLRequest()
            return authInterceptor?.adapt(request, for: target) ?? request
        } catch {
            RodiLogger.error("Request creation failed: \(target.path) error=\(error)")
            throw NetworkError(error)
        }
    }

    func performRequest<T: Decodable>(
        dtoType: T.Type,
        request: URLRequest
    ) async -> DataResponse<T, AFError> {
        await AF.request(request)
            .validate(statusCode: 200..<300)
            .serializingDecodable(dtoType, decoder: CodableManager.shared.responseDecoder)
            .response
    }

    func parseResponse<T: Decodable>(
        _ response: DataResponse<T, AFError>
    ) throws(NetworkError) -> T {
        switch response.result {
        case .success(let data):
            return data
        case .failure(let error):
            if error.isExplicitlyCancelledError {
                throw .cancel
            }

            if error.isSessionTaskError,
               let underlyingError = error.underlyingError as NSError?,
               underlyingError.domain == NSURLErrorDomain {
                switch underlyingError.code {
                case NSURLErrorTimedOut:
                    throw .timeOut
                case NSURLErrorNotConnectedToInternet,
                     NSURLErrorNetworkConnectionLost,
                     NSURLErrorCannotFindHost,
                     NSURLErrorCannotConnectToHost:
                    throw .networkUnavailable
                default:
                    throw .unknown(errorCode: String(underlyingError.code))
                }
            }

            if let serverError = decodeServerError(from: response.data) {
                throw .apiError(code: serverError.code, message: serverError.message)
            }

            if let statusCode = response.response?.statusCode {
                throw .httpStatusCode(statusCode)
            }

            throw .decodingFail
        }
    }

    func decodeServerError(from data: Data?) -> ServerErrorResponse? {
        guard let data else { return nil }

        let decoder = CodableManager.shared.responseDecoder
        if let error = try? decoder.decode(ServerErrorResponse.self, from: data) {
            return error
        }

        return try? decoder.decode(ServerErrorEnvelope.self, from: data).serverError
    }
}

private struct ServerErrorEnvelope: Decodable {
    let serverError: ServerErrorResponse?

    private enum CodingKeys: String, CodingKey {
        case data
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let error = try? container.decode(ServerErrorResponse.self, forKey: .error) {
            self.serverError = error
        } else {
            self.serverError = try? container.decode(ServerErrorResponse.self, forKey: .data)
        }
    }
}

//
//  KakaoDirectionsService.swift
//  Rodi
//
//  Created by Codex on 6/28/26.
//

import Foundation

enum KakaoDirectionsError: Error {
    case missingAPIKey
    case invalidCourse
    case emptyRoute
    case httpStatus(code: Int, message: String?)
    case decodingFailed(String)
    case networkFailed(String)

    var fallbackMessage: String {
        switch self {
        case .missingAPIKey:
            "도로 경로를 불러오지 못해 대체 경로로 표시 중이에요."
        case .invalidCourse:
            "경로 좌표가 아직 준비되지 않았어요."
        case .emptyRoute, .httpStatus, .decodingFailed, .networkFailed:
            "도로 경로를 불러오지 못해 대체 경로로 표시 중이에요."
        }
    }

    var logDescription: String {
        switch self {
        case .missingAPIKey:
            "missing_rest_api_key"
        case .invalidCourse:
            "invalid_course"
        case .emptyRoute:
            "empty_route"
        case .httpStatus(let code, let message):
            "http_status=\(code), message=\(message ?? "nil")"
        case .decodingFailed(let message):
            "decoding_failed=\(message)"
        case .networkFailed(let message):
            "network_failed=\(message)"
        }
    }
}

struct KakaoDirectionsService {
    private let kakaoRESTClient: KakaoRESTClient

    init(kakaoRESTClient: KakaoRESTClient = .init()) {
        self.kakaoRESTClient = kakaoRESTClient
    }

    func fetchRoute(points: [RodiRouteOverlayPoint]) async throws -> [RodiCoordinate] {
        guard
            let start = points.first(where: { $0.role == .start }) ?? points.first,
            let end = points.last(where: { $0.role == .end }) ?? points.last,
            start.id != end.id
        else {
            throw KakaoDirectionsError.invalidCourse
        }

        let waypoints = points
            .filter { $0.id != start.id && $0.id != end.id }
            .sorted { $0.sequence < $1.sequence }

        var components = URLComponents(string: "https://apis-navi.kakaomobility.com/v1/directions")
        components?.queryItems = [
            URLQueryItem(name: "origin", value: start.coordinate.kakaoQueryValue),
            URLQueryItem(name: "destination", value: end.coordinate.kakaoQueryValue),
            URLQueryItem(name: "priority", value: "RECOMMEND"),
            URLQueryItem(name: "summary", value: "false")
        ]

        if !waypoints.isEmpty {
            components?.queryItems?.append(
                URLQueryItem(
                    name: "waypoints",
                    value: waypoints.map(\.coordinate.kakaoQueryValue).joined(separator: "|")
                )
            )
        }

        guard let url = components?.url else {
            throw KakaoDirectionsError.invalidCourse
        }

        let response: KakaoRESTClient.Response
        do {
            response = try await kakaoRESTClient.get(url: url)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as KakaoRESTClient.TransportError {
            switch error {
            case .missingAPIKey:
                throw KakaoDirectionsError.missingAPIKey
            case .invalidHTTPResponse, .networkFailed:
                throw KakaoDirectionsError.networkFailed("transport_failed")
            }
        }

        RodiLogger.info("Kakao directions response status=\(response.statusCode)")
        guard (200..<300).contains(response.statusCode) else {
            let message = KakaoDirectionsErrorResponse.decodeMessage(from: response.data)
            throw KakaoDirectionsError.httpStatus(code: response.statusCode, message: message)
        }

        let decoded: KakaoDirectionsResponse
        do {
            decoded = try JSONDecoder().decode(KakaoDirectionsResponse.self, from: response.data)
        } catch {
            throw KakaoDirectionsError.decodingFailed(error.localizedDescription)
        }

        let path = decoded.routePath
        guard !path.isEmpty else {
            throw KakaoDirectionsError.emptyRoute
        }

        return path
    }
}

private struct KakaoDirectionsErrorResponse: Decodable {
    let code: Int?
    let msg: String?
    let message: String?
    let error: String?

    var bestMessage: String? {
        [msg, message, error]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    static func decodeMessage(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        if let decoded = try? JSONDecoder().decode(Self.self, from: data) {
            return decoded.bestMessage
        }
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct KakaoDirectionsResponse: Decodable {
    let routes: [KakaoDirectionsRoute]

    var routePath: [RodiCoordinate] {
        routes.first?.sections
            .flatMap(\.roads)
            .flatMap(\.coordinates) ?? []
    }
}

private struct KakaoDirectionsRoute: Decodable {
    let sections: [KakaoDirectionsSection]
}

private struct KakaoDirectionsSection: Decodable {
    let roads: [KakaoDirectionsRoad]
}

private struct KakaoDirectionsRoad: Decodable {
    let vertexes: [Double]

    var coordinates: [RodiCoordinate] {
        stride(from: 0, to: vertexes.count - 1, by: 2).map { index in
            RodiCoordinate(latitude: vertexes[index + 1], longitude: vertexes[index])
        }
    }
}

private extension RodiCoordinate {
    var kakaoQueryValue: String {
        "\(longitude),\(latitude)"
    }
}

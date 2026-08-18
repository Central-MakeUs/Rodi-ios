//
//  KakaoLocalPlaceSearchService.swift
//  Rodi
//

import Foundation

enum KakaoLocalPlaceSearchError: Error {
    case missingAPIKey
    case invalidRequest
    case httpStatus(Int)
    case decodingFailed
    case networkFailed

    var userMessage: String {
        switch self {
        case .missingAPIKey:
            "KAKAO_REST_API_KEY가 설정되지 않았어요."
        case .invalidRequest:
            "검색 요청을 만들지 못했어요."
        case .httpStatus(let statusCode):
            switch statusCode {
            case 401:
                "REST API 키 인증에 실패했어요."
            case 403:
                "카카오맵 API 사용 설정을 확인해 주세요."
            case 429:
                "카카오맵 API 호출 한도를 초과했어요."
            default:
                "카카오 검색 요청에 실패했어요. (HTTP \(statusCode))"
            }
        case .decodingFailed:
            "카카오 검색 응답을 해석하지 못했어요."
        case .networkFailed:
            "네트워크 연결을 확인해 주세요."
        }
    }
}

struct KakaoLocalPlaceSearchService {
    func searchPlaces(
        query: String,
        offset: Int = 0,
        limit: Int = 20
    ) async throws -> CourseRegistrationPlaceSearchPage {
        guard !KakaoConfiguration.restAPIKey.isEmpty else {
            throw KakaoLocalPlaceSearchError.missingAPIKey
        }

        let firstPage = offset / 15 + 1
        let lastPage = (offset + limit - 1) / 15 + 1
        var documents: [KakaoKeywordSearchResponseDTO.Document] = []
        var isEnd = false

        for page in firstPage...lastPage {
            let response = try await requestPage(query: query, page: page)
            documents.append(contentsOf: response.documents)
            isEnd = response.meta.isEnd
            if isEnd { break }
        }

        let firstDocumentIndex = offset - (firstPage - 1) * 15
        let items = documents
            .dropFirst(firstDocumentIndex)
            .prefix(limit)
            .map { $0.toModel() }
        return .init(items: Array(items), isEnd: isEnd || items.count < limit)
    }

    private func requestPage(
        query: String,
        page: Int
    ) async throws -> KakaoKeywordSearchResponseDTO {
        var components = URLComponents(
            string: "https://dapi.kakao.com/v2/local/search/keyword.json"
        )
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: "15")
        ]

        guard let url = components?.url else {
            throw KakaoLocalPlaceSearchError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(
            "KakaoAK \(KakaoConfiguration.restAPIKey)",
            forHTTPHeaderField: "Authorization"
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            if error is CancellationError {
                throw error
            }
            throw KakaoLocalPlaceSearchError.networkFailed
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw KakaoLocalPlaceSearchError.networkFailed
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw KakaoLocalPlaceSearchError.httpStatus(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(KakaoKeywordSearchResponseDTO.self, from: data)
        } catch {
            throw KakaoLocalPlaceSearchError.decodingFailed
        }
    }
}

private struct KakaoKeywordSearchResponseDTO: Decodable {
    let meta: Meta
    let documents: [Document]

    struct Meta: Decodable {
        let isEnd: Bool

        enum CodingKeys: String, CodingKey {
            case isEnd = "is_end"
        }
    }

    struct Document: Decodable {
        let id: String
        let placeName: String
        let categoryName: String
        let categoryGroupName: String
        let phone: String
        let addressName: String
        let roadAddressName: String
        let x: String
        let y: String

        enum CodingKeys: String, CodingKey {
            case id
            case placeName = "place_name"
            case categoryName = "category_name"
            case categoryGroupName = "category_group_name"
            case phone
            case addressName = "address_name"
            case roadAddressName = "road_address_name"
            case x, y
        }
    }
}

private extension KakaoKeywordSearchResponseDTO.Document {
    func toModel() -> CourseRegistrationPlaceSearchItem {
        .init(
            id: "place-\(id)",
            title: placeName,
            address: roadAddressName.nonEmpty ?? addressName,
            coordinate: Double(y).flatMap { latitude in
                Double(x).map { longitude in
                    RodiCoordinate(latitude: latitude, longitude: longitude)
                }
            },
            category: categoryGroupName.nonEmpty ?? categoryName.nonEmpty,
            phone: phone.nonEmpty
        )
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

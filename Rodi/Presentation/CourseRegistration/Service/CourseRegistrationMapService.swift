import Foundation

@MainActor
final class CourseRegistrationMapService {
    enum CurrentLocationResult {
        case resolved(RodiCoordinate)
        case unavailable
        case permissionDenied(LocationAuthorizationState)
    }

    private let locationService: MapLocationService

    init(locationService: MapLocationService? = nil) {
        self.locationService = locationService ?? MapLocationService()
    }

    func requestCurrentLocation() async -> CurrentLocationResult {
        switch await locationService.requestLocation() {
        case .resolved(let coordinate):
            .resolved(coordinate)
        case .unavailable:
            .unavailable
        case .permissionDenied(let authorizationState):
            .permissionDenied(authorizationState)
        }
    }

    func reverseGeocode(_ coordinate: RodiCoordinate) async throws -> String {
        guard !KakaoConfiguration.restAPIKey.isEmpty else {
            throw CourseRegistrationAddressLookupError.missingAPIKey
        }

        var components = URLComponents(
            string: "https://dapi.kakao.com/v2/local/geo/coord2address.json"
        )
        components?.queryItems = [
            URLQueryItem(name: "x", value: String(coordinate.longitude)),
            URLQueryItem(name: "y", value: String(coordinate.latitude))
        ]
        guard let url = components?.url else {
            throw CourseRegistrationAddressLookupError.invalidRequest
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
            throw CourseRegistrationAddressLookupError.networkFailed
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CourseRegistrationAddressLookupError.networkFailed
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw CourseRegistrationAddressLookupError.httpStatus(httpResponse.statusCode)
        }

        do {
            let response = try JSONDecoder().decode(CoordToAddressResponse.self, from: data)
            guard let document = response.documents.first else {
                throw CourseRegistrationAddressLookupError.addressNotFound
            }
            if let roadAddress = document.roadAddress?.addressName.nonEmpty {
                return roadAddress
            }
            if let address = document.address?.addressName.nonEmpty {
                return address
            }
            throw CourseRegistrationAddressLookupError.addressNotFound
        } catch let error as CourseRegistrationAddressLookupError {
            throw error
        } catch {
            throw CourseRegistrationAddressLookupError.decodingFailed
        }
    }
}

enum CourseRegistrationAddressLookupError: Error {
    case missingAPIKey
    case invalidRequest
    case httpStatus(Int)
    case decodingFailed
    case addressNotFound
    case networkFailed

    var userMessage: String {
        "주소를 불러오지 못했어요. 잠시 후 다시 시도해주세요."
    }
}

private struct CoordToAddressResponse: Decodable {
    let documents: [Document]

    struct Document: Decodable {
        let address: Address?
        let roadAddress: Address?

        enum CodingKeys: String, CodingKey {
            case address
            case roadAddress = "road_address"
        }
    }

    struct Address: Decodable {
        let addressName: String

        enum CodingKeys: String, CodingKey {
            case addressName = "address_name"
        }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

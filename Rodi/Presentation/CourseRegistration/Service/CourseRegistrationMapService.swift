import Foundation

@MainActor
final class CourseRegistrationMapService {
    enum CurrentLocationResult {
        case resolved(RodiCoordinate)
        case unavailable
        case permissionDenied(LocationAuthorizationState)
    }

    private let locationService: MapLocationService
    private let kakaoRESTClient: KakaoRESTClient

    init(
        locationService: MapLocationService? = nil,
        kakaoRESTClient: KakaoRESTClient? = nil
    ) {
        self.locationService = locationService ?? MapLocationService()
        self.kakaoRESTClient = kakaoRESTClient ?? KakaoRESTClient()
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

        do {
            let response = try await kakaoRESTClient.get(url: url)
            guard (200..<300).contains(response.statusCode) else {
                throw CourseRegistrationAddressLookupError.httpStatus(response.statusCode)
            }

            let decoded = try JSONDecoder().decode(CoordToAddressResponse.self, from: response.data)
            guard let document = decoded.documents.first else {
                throw CourseRegistrationAddressLookupError.addressNotFound
            }
            if let roadAddress = document.roadAddress?.addressName.nonEmpty {
                return roadAddress
            }
            if let address = document.address?.addressName.nonEmpty {
                return address
            }
            throw CourseRegistrationAddressLookupError.addressNotFound
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as CourseRegistrationAddressLookupError {
            throw error
        } catch let error as KakaoRESTClient.TransportError {
            switch error {
            case .missingAPIKey:
                throw CourseRegistrationAddressLookupError.missingAPIKey
            case .invalidHTTPResponse, .networkFailed:
                throw CourseRegistrationAddressLookupError.networkFailed
            }
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

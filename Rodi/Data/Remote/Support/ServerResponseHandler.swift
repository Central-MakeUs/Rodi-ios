import Foundation

enum ServerResponseHandler {
    enum MissingPayloadPolicy {
        case apiError
        case decodingFail
    }

    static func payload<T: Decodable, Target: TargetType>(
        _ target: Target,
        using networkManager: NetworkManager,
        as type: T.Type,
        missingPayloadPolicy: MissingPayloadPolicy = .apiError
    ) async throws(NetworkError) -> T {
        let response = try await networkManager.request(
            target,
            as: ServerResponse<T>.self
        )

        guard response.isSuccess else {
            throw .apiError(
                code: response.code,
                message: response.message
            )
        }

        guard let data = response.data else {
            switch missingPayloadPolicy {
            case .apiError:
                throw .apiError(
                    code: response.code,
                    message: response.message
                )
            case .decodingFail:
                throw .decodingFail
            }
        }

        return data
    }

    static func empty<Target: TargetType>(
        _ target: Target,
        using networkManager: NetworkManager
    ) async throws(NetworkError) {
        let response = try await networkManager.request(
            target,
            as: ServerResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            throw .apiError(
                code: response.code,
                message: response.message
            )
        }
    }
}

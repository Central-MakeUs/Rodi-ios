import Foundation

struct ServerResponse<T: Decodable>: Decodable {
    let isSuccess: Bool
    let code: String
    let message: String
    let data: T?
    let traceId: String?
}

struct EmptyResponse: Decodable {}

struct ServerErrorResponse: Decodable, Equatable {
    let code: String
    let message: String
    let traceId: String?

    private enum CodingKeys: String, CodingKey {
        case code
        case message
        case traceId
    }

    init(code: String, message: String, traceId: String? = nil) {
        self.code = code
        self.message = message
        self.traceId = traceId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = (try? container.decode(String.self, forKey: .code)) ?? "SERVER_ERROR"
        self.message = (try? container.decode(String.self, forKey: .message)) ?? "서버 오류가 발생했습니다."
        self.traceId = try? container.decode(String.self, forKey: .traceId)
    }
}

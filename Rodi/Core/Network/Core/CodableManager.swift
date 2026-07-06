//
//  CodableManager.swift
//  BoilerplateSwiftUI
//
//  Created by mac on 5/12/26.
//

import Foundation

// 무조건 좋은건 아님
// 네트워크같은 빈번한 요청이 아닌 ui vm에서는 별로 안 좋음 -> 무거워져서
public final class CodableManager: Sendable {

    public static let shared = CodableManager()

    private init () {}

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public var responseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

extension CodableManager {

    public func jsonEncoding<T: Encodable>(from value: T) throws -> Data {
        return try encoder.encode(value)
    }

    public func jsonDecoding<T:Decodable>(model: T.Type, from data: Data) throws -> T {
        return try decoder.decode(T.self, from: data)
    }

    public func toJSONSerialization(data: Data?) -> Any? {
        do {
            guard let data else {
                return nil
            }
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            return nil
        }
    }
}

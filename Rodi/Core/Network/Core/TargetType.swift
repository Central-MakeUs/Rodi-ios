//
//  TargetType.swift
//  BoilerplateSwiftUI
//
//  Created by mac on 5/14/26.
//

import Foundation
import Alamofire

public enum EncodingType {
    case url
    case json
}

public protocol TargetType {

    var method: HTTPMethod { get }

    var baseURL: String { get }

    var path: String { get }

    var optionalHeaders: HTTPHeaders? { get } // secretHeader 말고도 추가적인 헤더가 필요시

    var headers: HTTPHeaders { get } // 다 합쳐진 헤더

    var parameters: Parameters? { get }

    var body: Data? { get }

    var encodingType: EncodingType { get }

    var requiresAuthentication: Bool { get }

    var timeoutInterval: TimeInterval? { get }
}

extension TargetType {

    public var requiresAuthentication: Bool {
        false
    }

    public var timeoutInterval: TimeInterval? {
        nil
    }

    public var baseURL: String {
        ServerAPI.baseURL
    }


    public var headers: HTTPHeaders {
        var combine: HTTPHeaders = [
            "Accept": "application/json;charset=UTF-8",
            "Content-Type": "application/json;charset=UTF-8"
        ]
        if let optionalHeaders {
            optionalHeaders.forEach { header in
                combine.add(header)
            }
        }
        return combine
    }

    public func asURLRequest() throws(RouterError) -> URLRequest {
        let url = try baseURLToURL()

        var urlRequest = try urlToURLRequest(url: url)

        switch encodingType {
        case .url:
            do {
                urlRequest = try URLEncoding.queryString.encode(urlRequest, with: parameters)
            } catch {
                throw .encodingFail
            }
        case .json:
            do {
                if let body {
                    urlRequest.httpBody = body
                    if urlRequest.allHTTPHeaderFields?["Content-Type"] == nil {
                        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    }
                } else {
                    let request = try JSONEncoding.default.encode(urlRequest, withJSONObject: parameters)
                    urlRequest = request
                }
            } catch {
                throw .encodingFail
            }
        }

        if let timeoutInterval {
            urlRequest.timeoutInterval = timeoutInterval
        }

        return urlRequest
    }

    private func baseURLToURL() throws(RouterError) -> URL {
        do {
            let url = try baseURL.asURL()
            return url
        } catch let error as AFError {
            if case .invalidURL = error {
                throw .urlFail(url: baseURL)
            } else {
                throw .unknown(errorCode: "baseURLToURL")
            }
        } catch {
            throw .unknown(errorCode: "baseURLToURL")
        }
    }

    private func urlToURLRequest(url: URL) throws(RouterError) -> URLRequest {
        do {
            let urlRequest = try URLRequest(url: url.appending(path: path), method: method, headers: headers)

            return urlRequest
        } catch let error as AFError {
            if case .invalidURL = error {
                throw .urlFail(url: baseURL)
            } else {
                throw .unknown(errorCode: "urlToURLRequest")
            }
        } catch {
            throw .unknown(errorCode: "urlToURLRequest")
        }
    }

    public func requestToBody(_ request: Encodable) -> Data? {
        do {
            return try CodableManager.shared.jsonEncoding(from: request)
        } catch {
            RodiLogger.error("Request body encoding failed")
            return nil
        }
    }
}

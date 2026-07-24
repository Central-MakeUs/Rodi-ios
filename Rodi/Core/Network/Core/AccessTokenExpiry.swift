//
//  AccessTokenExpiry.swift
//  Rodi
//

import Foundation

enum AccessTokenExpiry {
    /// JWT의 exp claim을 기준으로 access token 갱신이 필요한지 판단한다.
    /// 형식을 해석할 수 없는 access token은 안전하게 갱신 대상으로 본다.
    static func needsRefresh(
        _ accessToken: String,
        now: Date = .now,
        leeway: TimeInterval = 60
    ) -> Bool {
        guard let expiryDate = expiryDate(from: accessToken) else {
            return true
        }

        return now.addingTimeInterval(leeway) >= expiryDate
    }
}

private extension AccessTokenExpiry {
    static func expiryDate(from accessToken: String) -> Date? {
        let segments = accessToken.split(separator: ".")
        guard segments.count >= 2,
              let payloadData = base64URLDecodedData(from: String(segments[1])),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let expiry = (payload["exp"] as? NSNumber)?.doubleValue
        else {
            return nil
        }

        return Date(timeIntervalSince1970: expiry)
    }

    static func base64URLDecodedData(from value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let paddingCount = (4 - base64.count % 4) % 4
        base64.append(String(repeating: "=", count: paddingCount))
        return Data(base64Encoded: base64)
    }
}

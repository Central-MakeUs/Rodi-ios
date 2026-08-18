//
//  BlockedMemberResponseDTO.swift
//  Rodi
//

import Foundation

struct BlockedMemberCursorPageResponseDTO: Decodable {
    let items: [BlockedMemberItemResponseDTO]
    let hasNext: Bool
    let nextCursor: String?
    let totalCount: Int64?
}

struct BlockedMemberItemResponseDTO: Decodable {
    let memberId: Int64
    let nickname: String?
    let blockedAt: String
}

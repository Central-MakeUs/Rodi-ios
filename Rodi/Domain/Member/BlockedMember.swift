//
//  BlockedMember.swift
//  Rodi
//

import Foundation

struct BlockedMember: Equatable, Identifiable {
    let id: Int
    let nickname: String?
    let blockedAt: Date

    var displayNickname: String {
        nickname?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "탈퇴한 회원"
    }
}

struct BlockedMemberPage: Equatable {
    let items: [BlockedMember]
    let hasNext: Bool
    let nextCursor: String?
    let totalCount: Int?
}

struct BlockedMemberQuery: Equatable {
    let size: Int
    let cursor: String?

    init(size: Int = 20, cursor: String? = nil) {
        self.size = size
        self.cursor = cursor
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

//
//  Entity.swift
//  Rodi
//
//  Created by mac on 8/21/26.
//

import Foundation

// TODO: Swift6 대응 필요 (데모데이 이후)

/// UI use model protocol
///
///     struct TestEntity: Entity {
///         let a: String (Sendable)
///     }
protocol Entity: Equatable, Sendable { }

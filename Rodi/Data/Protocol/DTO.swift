//
//  DTO.swift
//  Rodi
//
//  Created by mac on 8/21/26.
//

import Foundation

// TODO: Swift6 대응 필요 (데모데이 이후)

/// Network Struct Protocol
///
///
///     struct ExapmeDTO: DTO { ... }
protocol DTO: Decodable, Sendable, Equatable {}

/// Reqeust Network Struct Protocol
///
///
///     struct ExampleDTO: RequestDTO { ... }
protocol RequestDTO: Encodable, Sendable, Equatable {}

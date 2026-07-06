//
//  RodiLogger.swift
//  Rodi
//
//  Created by Codex on 6/27/26.
//

import Foundation
import SwiftyBeaver

enum RodiLogger {
    private static let log = SwiftyBeaver.self
    private static var isConfigured = false

    static func configure() {
        guard !isConfigured else { return }

        let console = ConsoleDestination()
        console.asynchronously = false
        console.useNSLog = true
        #if DEBUG
        console.minLevel = .debug
        #else
        console.minLevel = .warning
        #endif
        console.format = "$DHH:mm:ss.SSS$d $L $N.$F:$l - $M"
        log.addDestination(console)
        isConfigured = true
        log.info("Rodi logger configured")
    }

    static func verbose(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log.verbose(message(), file: file, function: function, line: line)
    }

    static func debug(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log.debug(message(), file: file, function: function, line: line)
    }

    static func info(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log.info(message(), file: file, function: function, line: line)
    }

    static func warning(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log.warning(message(), file: file, function: function, line: line)
    }

    static func error(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log.error(message(), file: file, function: function, line: line)
    }

    static func masked(_ value: String) -> String {
        guard !value.isEmpty else { return "empty" }
        guard value.count > 8 else { return "set(length=\(value.count))" }
        return "set(length=\(value.count), suffix=\(value.suffix(4)))"
    }

    static func coordinate(latitude: Double, longitude: Double) -> String {
        #if DEBUG
        return "(\(latitude), \(longitude))"
        #else
        return "(lat/lng hidden)"
        #endif
    }

    static func coordinate(_ coordinate: RodiCoordinate) -> String {
        Self.coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

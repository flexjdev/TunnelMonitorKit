//
//  TMLogger.swift
//  
//
//  Created by Chris J on 23/03/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation

/// Protocol defining a TunnelMonitor logger, allowing the use of custom logging formats and frameworks.
public protocol TMLogger {

    /// Sets this logger's minimum log level. Logs of lower severity than this will not be output.
    /// - Parameter level: The minimum log level that this logger will output.
    func setLogLevel(_ level: LogLevel)

    /// Output a log message with a specified severity.
    /// - Parameters:
    ///   - level: The log level, or severity of this message.
    ///   - message: The string contents of the message to output.
    func log(_ level: LogLevel, _ message: String)

}

/// Enum representing the varying log levels that a TMLogger can output.
public enum LogLevel: Int, CustomStringConvertible {
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case critical = 5

    /// The string representation of this log level.
    public var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARN"
        case .error: return "ERROR"
        case .critical: return "CRIT"
        }
    }
}

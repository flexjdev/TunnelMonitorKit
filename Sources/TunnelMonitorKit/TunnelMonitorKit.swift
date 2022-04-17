//
//  File 2.swift
//  
//
//  Created by Chris J on 23/03/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation

public class TunnelMonitorKit {
    /// Array of all registered loggers
    public static var loggers: [TMLogger] = []

    public init() { }

}

/// Convenience function that uses all registered loggers to output a message.
/// - Parameters:
///   - level: The log level to output the message under.
///   - message: The string message to
func log(_ level: LogLevel, _ message: String) {
    TunnelMonitorKit.loggers.forEach { $0.log(level, message) }
}

//
//  TMOSLogger.swift
//  
//
//  Created by Chris J on 23/03/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import os.log
import Foundation

/// A TunnelMonitor Logger implementation, based on the system logger. Distinguishes logs originating from the host
/// application and network extension.
public class TMOSLogger: TMLogger {

    private let targetPrefix = Bundle.main.bundlePath.hasSuffix(".appex") ? "TUN" : "APP"
    private var minimumLogLevel: LogLevel = .info

    public init() { }

    public func setLogLevel(_ level: LogLevel) {
        minimumLogLevel = level
    }

    public func log(_ level: LogLevel, _ message: String) {
        if level.rawValue >= minimumLogLevel.rawValue {
            os_log("%s", "[TM:\(targetPrefix)] \(level.description): \(message)")
        }
    }
}

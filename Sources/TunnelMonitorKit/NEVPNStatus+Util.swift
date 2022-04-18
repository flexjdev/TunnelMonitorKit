//
//  NEVPNStatus+Util.swift
//  TunnelMonitorKit
//
//  Created by Chris J on 18/04/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import NetworkExtension

extension NEVPNStatus: CustomStringConvertible {

  /// A textual representation of this instance
  public var description: String {
    switch self {
    case .invalid: return "invalid"
    case .disconnected: return "disconnected"
    case .connecting: return "connecting"
    case .connected: return "connected"
    case .reasserting: return "reasserting"
    case .disconnecting: return "disconnecting"
    default: return "unknown"
    }
  }

}

extension NEVPNStatus: CaseIterable {
    public static var allCases: [NEVPNStatus] {
        return [.invalid, .disconnected, .disconnecting, .connecting, .connected, .reasserting]
    }
}

//
//  NEProviderStopReason+Extension.swift
//  TunnelMonitorKit
//
//  Created by Chris J on 13/08/2021.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import NetworkExtension

extension NEProviderStopReason: CustomStringConvertible {

  /// A textual representation of this instance.
  public var description: String {
    switch self {
    case .none: return "None"
    case .userInitiated: return "User Initiated"
    case .providerFailed: return "Provider Failed"
    case .noNetworkAvailable: return "No Network Available"
    case .unrecoverableNetworkChange: return "Unrecoverable Network Change"
    case .providerDisabled: return "Provider Disabled"
    case .authenticationCanceled: return "Authentication Cancelled"
    case .configurationFailed: return "Configuration Failed"
    case .idleTimeout: return "Idle Timeout"
    case .configurationDisabled: return "Configuration Disabled"
    case .configurationRemoved: return "Configuration Removed"
    case .superceded: return "Superceded"
    case .userLogout: return "User Logout"
    case .userSwitch: return "User Switch"
    case .appUpdate: return "App Update"
    case .connectionFailed: return "Connection Failed"
    case .sleep: return "Sleep"
    default: return "Uknown"
    }
  }
}

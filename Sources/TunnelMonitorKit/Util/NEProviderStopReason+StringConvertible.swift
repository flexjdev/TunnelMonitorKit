//
//  NEProviderStopReason+Extension.swift
//  HybridLinkV3
//
//  Created by Chris J on 13/08/2021.
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
    case .connectionFailed: return "ConnectionFailed"
    case .sleep: return "Sleep"
    default: return "Uknown"
    }
  }
}

extension NEProviderStopReason: CustomDebugStringConvertible {

  /// A textual representation of this instance, suitable for debugging.
  public var debugDescription: String {
    switch self {
    case .none: return "No specific reason."
    case .userInitiated: return "The user stopped the provider extension."
    case .providerFailed: return "The provider failed to function correctly."
    case .noNetworkAvailable: return "No network connectivity is currently available."
    case .unrecoverableNetworkChange: return "The device’s network connectivity changed."
    case .providerDisabled: return "The provider was disabled."
    case .authenticationCanceled: return "The authentication process was canceled."
    case .configurationFailed: return "The configuration is invalid."
    case .idleTimeout: return "The session timed out."
    case .configurationDisabled: return "The configuration was disabled."
    case .configurationRemoved: return "The configuration was removed."
    case .superceded: return "The configuration was superceded by a higher-priority configuration."
    case .userLogout: return "The user logged out."
    case .userSwitch: return "The current console user changed."
    case .appUpdate: return "App Update"
    case .connectionFailed: return "The connection failed."
    case .sleep: return "The configuration enabled disconnect on sleep and the device went to sleep."
    default: return "Uknown stop reason."
    }
  }
}

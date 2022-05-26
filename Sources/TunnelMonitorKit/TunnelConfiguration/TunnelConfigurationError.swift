//
//  TunnelConfigurationError.swift
//  TunnelMonitorKit
//
//  Created by Chris J on 13/05/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation

/// Contains information about why Tunnel configuration failed
public enum TMTunnelConfigurationError: Error {

    /// The configuration dictionary is missing
    case missingConfiguration

    /// General tunnel settings were not present in the configuration dictionary
    case missingNetworkSettings

    /// User specific settings were not present in the configuration dictionary
    case missingUserConfiguration

    /// Could not decode the data present in the configuration dictionary
    case configurationDecodingFailed(decodeError: Error)

    /// Failed to apply the network settings
    case settingsApplicationFailed(error: Error)
}

extension TMTunnelConfigurationError: CustomStringConvertible {

    /// Provides a meaningful description for each error type
    public var description: String {
        switch self {
        case .missingConfiguration:
            return "Configuration dictionary is missing."
        case .missingNetworkSettings:
            return "Configuration dictionary does not contain \(TMTunnelConfigurationKey.networkSettings.rawValue)"
        case .missingUserConfiguration:
            return "Configuration dictionary does not contain \(TMTunnelConfigurationKey.userConfiguration.rawValue)"
        case .configurationDecodingFailed(let error):
            return "Failed to decode data retrieved from the configuration dictionary: \(error)"
        case .settingsApplicationFailed(let error):
            return "Failed to apply network settings: \(error)"
        }
    }

}

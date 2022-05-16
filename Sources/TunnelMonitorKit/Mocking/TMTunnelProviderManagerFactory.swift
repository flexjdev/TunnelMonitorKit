//
//  TMPacketTunnelProvider.swift
//  TunnelMonitorKit
//
//  Created by Chris J on 16/05/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation
import NetworkExtension

/// Responsible for constructing mock or native packet tunnel provider managers.
public class TMTunnelProviderManagerFactory {

    /// Creates a mock provider manager, capable of executing tunnel provider logic implemented by the given
    /// `TMPacketTunnelProvider`.
    /// - Parameters:
    ///   - type: The type of provider to instantiate.
    ///   - networkSettings: General network settings.
    ///   - userConfiguration: Service specific configuration, required to configure the given `Provider`.
    public static func createMockProviderManager<UserConfiguration: Codable, Provider: TMPacketTunnelProvider>(
        ofType type: Provider.Type,
        networkSettings: TMNetworkSettings,
        userConfiguration: UserConfiguration
    ) throws -> TMMockTunnelProviderManager {
        return try TMMockTunnelProviderManager(
            provider: Provider(),
            networkSettings: networkSettings,
            userConfiguration: userConfiguration
        )
    }

    /// Loads a native tunnel ptovider manager.
    /// - Parameters:
    ///   - tunnelSettings: General tunnel settings.
    ///   - networkSettings: General network settings.
    ///   - userConfiguration: Service specific configuration, required to configure the given `Provider`.
    ///   - completionHandler: Completion handler executed when the tunnel loading finishes.
    public static func loadNativeProviderManager<UserConfiguration: Codable>(
        tunnelSettings: TMTunnelSettings,
        networkSettings: TMNetworkSettings,
        userConfiguration: UserConfiguration,
        completionHandler: @escaping (TMNativeTunnelProviderManager?) -> Void
    ) {
        /// Initialise VPNManager, which also saves/updates a tunnel configuration to the phone's VPN settings
        NETunnelProviderManager.loadAllFromPreferences { (savedManagers, error) in
            if let error = error {
                log(.error, "Failed to load list of tunnel provider managers with error: \(error)")
                completionHandler(nil)
                return
            }
            guard let savedManager = savedManagers?.first else {
                log(.error, "No tunnel provider managers saved to Network Extension preferences.")
                completionHandler(nil)
                return
            }
            savedManager.loadFromPreferences { (error) in
                if let error = error {
                    log(.error, "Failed to load tunnel provider manager: \(savedManager) error: \(error)")
                    completionHandler(nil)
                    return
                }

                let provider = NETunnelProviderProtocol()
                provider.providerBundleIdentifier = tunnelSettings.tunnelBundleID

                let encoder = JSONEncoder()
                do {
                    let networkSettingsData = try encoder.encode(networkSettings)
                    let userConfigurationData = try encoder.encode(userConfiguration)
                    let config: [String: Any] = [
                        TMTunnelConfigurationKey.networkSettings.rawValue: networkSettingsData as Any,
                        TMTunnelConfigurationKey.userConfiguration.rawValue: userConfigurationData as Any
                    ]

                    provider.providerConfiguration = config
                    provider.serverAddress = networkSettings.tunnelRemoteAddress
                    provider.disconnectOnSleep = tunnelSettings.disconnectOnSleep

                    savedManager.localizedDescription = tunnelSettings.managerLocalizedDescription
                    savedManager.protocolConfiguration = provider
                    savedManager.isEnabled = true

                    savedManager.saveToPreferences { error in
                        if let error = error {
                            log(.error, "Failed to save tunnel provider manager: \(savedManager) error: \(error)")
                        }
                        let nativeManager = TMNativeTunnelProviderManager(provider: savedManager)
                        completionHandler(nativeManager)
                    }
                } catch {
                    log(.error, "Failed to encode tunnel configuration data structures \(error)")
                    completionHandler(nil)
                }
            }
        }
    }

}

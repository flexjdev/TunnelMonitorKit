//
//  TMPacketTunnelProviderNative.swift
//  TunnelMonitorKit
// 
//  Created by Chris J on 26/05/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import NetworkExtension

/// A real/native packet tunnel provider.
///
/// You must subclass this class, constraining the `TunnelProvider` to your implementation of the
/// `TMPacketTunnelProvider` protocol, with the info.plist file pointing to it via the `NSExtensionPrincipalClass`
/// entry.
///
/// ```
/// public class MyTunnelProvider: TMPacketTunnelProvider { /* implementation of required methods */ }
/// open class MyNativeTunnelProvider: TMPacketTunnelProviderNative<MyTunnelProvider> { }
/// ```
open class TMPacketTunnelProviderNative<TunnelProvider: TMPacketTunnelProvider>: NEPacketTunnelProvider {

    let provider: TunnelProvider

    override public required init() {
        provider = TunnelProvider()
        super.init()
    }

    private var configuration: [String: Any]? {
        return (self.protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration
    }

    private func configureProvider(completionHandler: @escaping (TMTunnelConfigurationError?) -> Void) {
        guard let config = configuration else {
            completionHandler(.missingConfiguration)
            return
        }

        let userConfigData = config[TMTunnelConfigurationKey.userConfiguration.rawValue] as? Data
        guard let networkSettingsData = config[TMTunnelConfigurationKey.networkSettings.rawValue] as? Data else {
            completionHandler(TMTunnelConfigurationError.missingNetworkSettings)
            return
        }

        do {
            let networkSettings = try JSONDecoder().decode(TMNetworkSettings.self, from: networkSettingsData)
            let settings = networkSettings.packetTunnelNetworkSettings

            setTunnelNetworkSettings(settings) { error in
                if let error = error {
                    completionHandler(.configurationDecodingFailed(decodeError: error))
                    return
                }
                self.provider.configureTunnel(
                    userConfigurationData: userConfigData,
                    settingsApplicationBlock: self.setTunnelNetworkSettings
                ) { error in
                    if let error = error {
                        completionHandler(error)
                        return
                    }
                    completionHandler(nil)
                }
            }
        } catch {
            completionHandler(.configurationDecodingFailed(decodeError: error))
        }

    }

    override public func startTunnel(
        options: [String: NSObject]? = nil,
        completionHandler: @escaping (Error?) -> Void
    ) {
        log(.info, "Configuring native packet tunnel provider...")
        configureProvider { error in
            if let error = error {
                log(.error, "Packet tunnel configuration failed: \(error)")
                completionHandler(error)
                return
            }

            self.provider.startTunnel(options: options) { error in
                if let error = error {
                    log(.error, "Packet tunnel failed to start: \(error)")
                }
                completionHandler(error)
            }
        }
    }

    override public func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        log(.info, "Stopping tunnel provider with reason: \(reason)")
        provider.stopTunnel(with: reason, completionHandler: completionHandler)
    }

    override public func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        provider.handleAppMessage(messageData, completionHandler: completionHandler)
    }
}

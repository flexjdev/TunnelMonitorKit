//
//  TMPacketTunnelProvider.swift
//  TunnelMonitorKit
//
//
//  Created by Chris J on 17/04/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation
import NetworkExtension

/// Allows for a single implementation to be executed as a tunnel provider on network extension targets, as well as in
/// the container app target. This allows the tunnel provider implementation to be mocked and tested when deploying to
/// simulator target environments. Limitations include not having access to the packetFlow object when mocking, making
/// actual VPN implementations near impossible when running in the app layer.
///
/// TMPacketTunnelProvider must be a protocol, as instances of NEPacketTunnelProvider and its subclasses cannot be
/// instantiated on non-network extension targets, while a native packet tunnel provider must inherit from this class in
/// order to be instantiated by the system. The workaround is to define a generic subclass of a class that
/// implements the provider protocol for running on network extension targets
/// (`TMPacketTunnelProviderNative<T: TMPacketTunnelProvider>`), and create a class that inherits from the
/// same provider protocol implementation for mocking (`TMMockTunnelProviderManager`). This allows a single
/// implementation to instantiated on, and outside network extension targets.
///
/// The Packet Tunnel target must define a `TMPacketTunnelProviderNative` subclass constrained to an implementation of
/// the `TMPacketTunnelProvider` protocol, with the info.plist file pointing to it via the `NSExtensionPrincipalClass`
/// entry.
public protocol TMPacketTunnelProvider: AnyObject {

    init()

    /// This configuration function is invoked when the tunnel is being started by a TMTunnelProviderManager. It must
    /// perform any set up required to perform its job, and call the completion handler with `nil` after configuration
    /// is finished and the tunnel is ready to start, or with a `TMTunnelConfigurationError` when an unrecoverable
    /// error is encountered and the tunnel cannot be configured and started.
    ///
    /// Any specific functionality can be configured using the `userConfigurationData` object, which is a serialized
    /// representation of the user configuration object passed to the constructors of `TMTunnelProviderManager`
    /// mock and native subclasses.
    ///
    /// - Parameters:
    ///   - userConfigurationData: Serialized representation of the user configuration object passed to the constructors
    ///   of `TMTunnelProviderManager` subclasses, or nil if no user configuration was supplied.
    ///   - settingsApplicationBlock: The block which applies the tunnel's protocol configuration object.
    ///   - completionHandler: The completion handler which signals configuration completion to the provider manager.
    func configureTunnel(
        userConfigurationData: Data?,
        settingsApplicationBlock: @escaping (NETunnelNetworkSettings?, ((Error?) -> Void)?) -> Void,
        completionHandler: @escaping (TMTunnelConfigurationError?) -> Void
    )

    /// This method is invoked by the provider manager after configuration of the tunnel in the `configureTunnel`
    /// method finishes without any errors. The implementation should start the user defined service in this method and
    /// call the completion handler with `nil` after the service has been successfully started, otherwise with an Error.
    /// - Parameters:
    ///   - options: Currently unused options dictionary that may be used for extra configuration in the future.
    ///   - completionHandler: Completion handler used to report a successful startup, or any errors.
    func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void)

    /// This method is invoked by the provider manager when it receives a signal to stop the tunnel. The implementation
    /// should stop it's service and perform any necessary cleanup before calling the completion handler to indicate the
    /// tunnel has been stopped.
    /// - Parameters:
    ///   - reason: The reason for stopping the tunnel
    ///   - completionHandler: Completion handler used to signal that the tunne lhas been stopped.
    func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void)

    /// This method is invoked whenever the tunnel receives a message from the host application. This communication
    /// protocol is bi-directional, but can only be initiated by the host application. A response can be sent to the
    /// host application using the completion handler.
    ///
    /// The recommended usage is to define a `MessageRouter` on the implementation of this protocol and register
    /// handlers during tunnel configuration, for each type of request that the host application is able to send. It is
    /// a good idea to define a general request which is polled at a time interval, with a response that contains the
    /// general state of the tunnel, when real-time information about the tunnel is required.
    ///
    /// ```
    /// let request = try! decoder.decode(MessageContainer.self, from: messageData)
    /// appMessageRouter.handle(message: request, completionHandler: handler)
    /// ```
    ///
    /// - Parameters:
    ///   - messageData: A serialized representation of the incoming host application request.
    ///   - completionHandler: A block which sends a response to the host application.
    func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?)

}

/// A real/native packet tunnel provider.
///
/// You must subclass this class, constraining the `TunnelProviderImplementation` to your implementation of the
/// `TMPacketTunnelProvider` protocol, with the info.plist file pointing to it via the `NSExtensionPrincipalClass`
/// entry.
///
/// ```
/// public class MyTunnelProvider: TMPacketTunnelProvider { /* implementation of required methods */ }
/// open class MyNativeTunnelProvider: TMPacketTunnelProviderNative<MyTunnelProvider> { }
/// ```
open class TMPacketTunnelProviderNative<TunnelProviderImplementation: TMPacketTunnelProvider>: NEPacketTunnelProvider {

    let provider: TunnelProviderImplementation

    override public required init() {
        provider = TunnelProviderImplementation()
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

    override public func startTunnel(options: [String: NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
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
        provider.stopTunnel(with: reason, completionHandler: completionHandler)
        log(.info, "stop")
    }

    override public func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        provider.handleAppMessage(messageData, completionHandler: completionHandler)
    }
}

public class TMTunnelProviderManagerFactory {

    public static func loadProviderManager<UserConfiguration: Codable, ProviderType: TMPacketTunnelProvider>(
        ofType type: ProviderType.Type,
        mocked: Bool,
        tunnelSettings: TMTunnelSettings,
        networkSettings: TMNetworkSettings,
        userConfiguration: UserConfiguration,
        completionHandler: @escaping (TMTunnelProviderManager?) -> Void
    ) {
        if mocked {
            do {
                let mockedManager = try createMockProviderManager(
                    ofType: type,
                    networkSettings: networkSettings,
                    userConfiguration: userConfiguration
                )
                completionHandler(mockedManager)
            } catch {
                completionHandler(nil)
            }
        } else {
            loadNativeProviderManager(
                tunnelSettings: tunnelSettings,
                networkSettings: networkSettings,
                userConfiguration: userConfiguration
            ) { providerManager in
                guard let providerManager = providerManager else {
                    completionHandler(nil)
                    return
                }
                completionHandler(providerManager)
            }
        }
    }

    public static func createMockProviderManager<UserConfiguration: Codable, ProviderType: TMPacketTunnelProvider>(
        ofType: ProviderType.Type,
        networkSettings: TMNetworkSettings,
        userConfiguration: UserConfiguration
    ) throws -> TMMockTunnelProviderManager {
        return try TMMockTunnelProviderManager(
            provider: ProviderType(),
            networkSettings: networkSettings,
            userConfiguration: userConfiguration
        )
    }

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
                log(.error, "Failed to load")
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

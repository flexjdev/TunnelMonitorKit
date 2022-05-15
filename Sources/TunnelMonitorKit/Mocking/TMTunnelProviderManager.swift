//
//  TMTunnelProviderManager.swift
//  
//
//  Created by Chris J on 14/05/2022.
//

import NetworkExtension
import Foundation

public protocol TMTunnelProviderManagerDelegate: AnyObject {

    func tunnelStateChanged(to state: NEVPNStatus)

    /// Invoked every time the service state changes, including traffic and gateway changes
    func serviceStateChanged<T: Codable>(manager: TMExtensionManager<T>, to state: T)
}

/// A base class allowing native and mock network extensions to be used interchangebly.
public class TMTunnelProviderManager {

    init() {}

    public func startTunnel() { }
    public func stopTunnel() { }

    public weak var delegate: TMTunnelProviderManagerDelegate?

    public var session: TMTunnelProviderSession? { fatalError("Must override") }

    public var tunnelMonitor: TunnelMonitor { fatalError("Must override") }

    /// Current status of the network extension
    public var tunnelStatus: NEVPNStatus { fatalError("Please use Mock or Native TunelProviderManager.") }

    private var tunnelManager: NETunnelProviderManager { fatalError("please") }

}

public class TMMockTunnelProviderManager: TMTunnelProviderManager {

    private let provider: TMPacketTunnelProvider
    private let mockSession = TMTunnelProviderSessionMock()
    private let monitor = TunnelMonitor()
    private let networkSettings: TMNetworkSettings
    private let userConfigurationData: Data?

    private var currentTunnelStatus: NEVPNStatus = .invalid {
        didSet {
            mockSession.setStatus(currentTunnelStatus)
            log(.debug, "Notifying delegate of status change: \(oldValue) -> \(currentTunnelStatus)")
            delegate?.tunnelStateChanged(to: currentTunnelStatus)
        }
    }

    public init<UserConfiguration: Codable>(
        provider: TMPacketTunnelProvider,
        networkSettings: TMNetworkSettings,
        userConfiguration: UserConfiguration?
    ) throws {
        self.provider = provider
        self.networkSettings = networkSettings

        if let userConfiguration = userConfiguration {
            self.userConfigurationData = try JSONEncoder().encode(userConfiguration)
        } else {
            self.userConfigurationData = nil
        }

        mockSession.setProvider(provider)
    }

    override public var tunnelStatus: NEVPNStatus { currentTunnelStatus }
    override public var tunnelMonitor: TunnelMonitor { monitor }
    override public var session: TMTunnelProviderSession? { mockSession }

    private func configureProvider(completionHandler: @escaping (TMTunnelConfigurationError?) -> Void) {
        provider.configureTunnel(
            userConfigurationData: userConfigurationData,
            settingsApplicationBlock: { _, completion in completion?(nil) },
            completionHandler: completionHandler
        )
    }

    override public func startTunnel() {
        currentTunnelStatus = .connecting
        log(.info, "Configuring mock packet tunnel provider...")

        configureProvider { error in
            if let error = error {
                log(.error, "Failed to configure mock tunnel provider: \(error)")
                return
            }

            self.provider.startTunnel(options: nil) { error in
                if let error = error {
                    self.currentTunnelStatus = .disconnecting
                    self.currentTunnelStatus = .disconnected
                    log(.error, "Failed to start mock tunnel provider: \(error)")
                    return
                }
                self.currentTunnelStatus = .connected
                log(.info, "Mock packet tunnel provider successfully started")
            }
        }
    }

    override public func stopTunnel() {
        provider.stopTunnel(with: .userInitiated) {
            log(.info, "Mock packet tunnel stopped")
        }
    }
}

/// Class that manages the vpn network extension - invoked by the container app to launch the network extension
public class TMNativeTunnelProviderManager: TMTunnelProviderManager {

    private let monitor = TunnelMonitor()
    private let providerManager: NETunnelProviderManager

    private var pollingInterval = 1.0

    override public var tunnelStatus: NEVPNStatus { session?.status ?? .invalid }
    override public var tunnelMonitor: TunnelMonitor { monitor }

    /// Initialise VPNManager, which also saves/updates a tunnel configuration to the phone's VPN settings
    public init(provider: NETunnelProviderManager) {
        providerManager = provider
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleVPNStatusChange),
            name: Notification.Name.NEVPNStatusDidChange,
            object: nil
        )
    }

    override public var session: TMTunnelProviderSession? {
        if let providerSession = providerManager.connection as? NETunnelProviderSession {
            return TMTunnelProviderSessionNative(nativeSession: providerSession)
        }
        return nil
    }

    override public func startTunnel() {
        guard let session = session, session.status != .connected else {
            log(.error, "Failed to start: tunnel is already connected!")
            return
        }
        do {
            try providerManager.connection.startVPNTunnel()
        } catch {
            print("\(error)")
            log(.error, "Failed to open a connection to the VPN Tunnel: \(error)")
        }
    }

    /// Stop the service, closing the existing VPN Tunnel.
    override public func stopTunnel() {
        providerManager.connection.stopVPNTunnel()
        tunnelMonitor.stopMonitoring()
    }

    @objc private func handleVPNStatusChange() {
        log(.info, "Tunnel status changed: \(tunnelStatus.description)")
        delegate?.tunnelStateChanged(to: tunnelStatus)
    }

}

//
//  TMTunnelProviderManager.swift
//  TunnelMonitorKit
//
//  Created by Chris J on 14/05/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import NetworkExtension
import Foundation

/// Defines events describing changes to the state of the tunnel provider, and the specific service it provides.
public protocol TMTunnelProviderManagerDelegate: AnyObject {

    /// Invoked whenever the tunnel provider state changes.
    func tunnelStateChanged(to state: NEVPNStatus)

    /// Invoked every time the service state changes. This contains information specific to the service provided by the
    /// tunnel provider, represented by an instance the generic parameter `ServiceInfo`.`
    func serviceStateChanged<ServiceInfo: Codable>(to state: ServiceInfo)
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

    public func send<Request: Codable, Response: Codable>(
        message: Request,
        responseHandler: @escaping (Result<Response, TMCommunicationError>) -> Void
    ) {
        tunnelMonitor.send(message: message, responseHandler: responseHandler)
    }

    public func send<Request: Codable>(message: Request) {
        tunnelMonitor.send(message: message) { (_: Result<Data, TMCommunicationError>) in }
    }

    public func startMonitoring<ServiceInfoRequest: Codable, ServiceInfoResponse: Codable>(
        withRequestBuilder requestBuilder: @escaping () -> ServiceInfoRequest,
        responseHandler: @escaping (Result<ServiceInfoResponse, TMCommunicationError>) -> Void,
        pollInterval: TimeInterval = 1.0
    ) {
        guard let session = session, session.status == .connected else {
            log(.error, "Unable to monitor session - incorrect state")
            return
        }
        tunnelMonitor.startMonitoring(
            session: session,
            withRequestBuilder: requestBuilder,
            responseHandler: responseHandler,
            pollInterval: pollInterval
        )
    }

    public func stopMonitoring() {
        tunnelMonitor.stopMonitoring()
    }

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

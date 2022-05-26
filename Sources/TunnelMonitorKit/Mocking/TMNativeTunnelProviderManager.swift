//
//  TMNativeTunnelProviderManager.swift
//  TunnelMonitorKit
// 
//  Created by Chris J on 26/05/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import NetworkExtension

/// Class that manages the vpn network extension. The native tunnel provider manager is essentially a wrapper around a
/// real tunnel provider manager.
public class TMNativeTunnelProviderManager: TMTunnelProviderManager {

    private let monitor = TunnelMonitor()
    private let providerManager: NETunnelProviderManager

    private var pollingInterval = 1.0

    override public var tunnelStatus: NEVPNStatus { session?.status ?? .invalid }
    override public var tunnelMonitor: TunnelMonitor { monitor }

    /// Initialise VPNManager, which also saves/updates a tunnel configuration to the phone's VPN settings
    init(provider: NETunnelProviderManager) {
        providerManager = provider
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleVPNStatusChange),
            name: Notification.Name.NEVPNStatusDidChange,
            object: nil
        )
    }

    override var session: TMTunnelProviderSession? {
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

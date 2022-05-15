//
//  PacketTunnelConfiguration.swift
//  TunnelMonitorKit
//
//  Created by Chris J on 13/05/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation
import NetworkExtension

/// Contains string keys used to pass Tunnel Configuration objects between the container app and the VPN extension
public enum TMTunnelConfigurationKey: String {

    /// General tunnel configuration
    case networkSettings = "TMNetworkSettingsConfiguration"
    /// User specific configuration
    case userConfiguration = "TMUserConfiguration"
}

/// Defines general settings for a packet tunnel network extension.
public struct TMTunnelSettings {

    let tunnelBundleID: String
    let managerLocalizedDescription: String
    let disconnectOnSleep: Bool

    public init(tunnelBundleID: String, managerLocalizedDescription: String, disconnectOnSleep: Bool) {
        self.tunnelBundleID = tunnelBundleID
        self.managerLocalizedDescription = managerLocalizedDescription
        self.disconnectOnSleep = disconnectOnSleep
    }
}

/// Defines network settings for a packet tunnel network extension, made available to the packet tunnel provider during
/// configuration. See the `configureTunnel` method of `TMPacketTunnelProvider`. It is invoked when mock or native
/// providers are started by a `TMPacketTunnelProviderManager`.
public struct TMNetworkSettings: Codable {
    let tunnelRemoteAddress: String
    let includedRoutes, excludedRoutes: String
    let tunnelAddress, tunnelSubnet, dns: String
    let tunnelOverheadBytes: Int?
    let mtu: Int

    public init(
        tunnelRemoteAddress: String,
        includedRoutes: String, excludedRoutes: String,
        tunnelAddress: String, subnet: String,
        tunnelOverheadBytes: Int? = 4,
        dns: String, mtu: Int
    ) {
        self.tunnelRemoteAddress = tunnelRemoteAddress
        self.includedRoutes = includedRoutes
        self.excludedRoutes = excludedRoutes
        self.tunnelAddress = tunnelAddress
        self.tunnelSubnet = subnet
        self.dns = dns
        self.tunnelOverheadBytes = tunnelOverheadBytes
        self.mtu = mtu
    }

    /// Constructs a settings object to be consumed by the VPN extension.
    public var packetTunnelNetworkSettings: NEPacketTunnelNetworkSettings {
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: tunnelRemoteAddress)

        let ipv4Settings = NEIPv4Settings(addresses: [tunnelAddress], subnetMasks: [tunnelSubnet])
        ipv4Settings.includedRoutes = TMNetworkSettings.parseRoutes(string: includedRoutes)
        ipv4Settings.excludedRoutes = TMNetworkSettings.parseRoutes(string: excludedRoutes)

        networkSettings.ipv4Settings = ipv4Settings

        if let overheadBytes = tunnelOverheadBytes {
            networkSettings.tunnelOverheadBytes = NSNumber(value: overheadBytes)
        }
        networkSettings.mtu = NSNumber(value: mtu)
        networkSettings.dnsSettings = NEDNSSettings(servers: dns.components(separatedBy: ","))

        return networkSettings
    }

    private static func parseRoutes(string: String) -> [NEIPv4Route] {
        return string.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap { NEIPv4Route(from: String($0)) }
    }
}

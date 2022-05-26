//
//  File.swift
//  TunnelMonitorKit
// 
//  Created by Chris J on 26/05/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation
import NetworkExtension
import XCTest
@testable import TunnelMonitorKit

final class TMNetworkSettingsTests: XCTestCase {

    private var networkSettings: TMNetworkSettings {
        TMNetworkSettings(
            tunnelRemoteAddress: "1.2.3.4",
            includedRoutes: "255.255.255.255:0.0.0.0", excludedRoutes: "0.0.0.0:0.0.0.0",
            tunnelAddress: "10.0.0.1", subnet: "255.255.255.0",
            dns: "8.8.8.8", mtu: 1024
        )
    }

    func testNetworkSettingsGeneratedCorrectly() {
        let settings = networkSettings.packetTunnelNetworkSettings
        XCTAssertEqual(settings.mtu?.intValue, networkSettings.mtu)
        XCTAssertEqual(settings.tunnelRemoteAddress, networkSettings.tunnelRemoteAddress)
        XCTAssert(settings.ipv4Settings?.includedRoutes?.count == 1)
        XCTAssert(settings.ipv4Settings?.excludedRoutes?.count == 1)
        XCTAssert(settings.dnsSettings?.servers.contains(networkSettings.dns) == true)
    }
}

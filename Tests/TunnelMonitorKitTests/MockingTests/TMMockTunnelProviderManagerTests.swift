//
//  TMMockTunnelProviderManagerTests.swift
//  TunnelMonitorKit
// 
//  Created by Chris J on 25/05/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation
import NetworkExtension
import XCTest
@testable import TunnelMonitorKit

final class TMMockTunnelProviderManagerTests: XCTestCase {

    static var configurationInvocation: XCTestExpectation!
    static var appMessageHandlerInvocation: XCTestExpectation!

    private var networkSettings: TMNetworkSettings {
        TMNetworkSettings(
            tunnelRemoteAddress: "1.2.3.4",
            includedRoutes: "255.255.255.255", excludedRoutes: "0.0.0.0",
            tunnelAddress: "10.0.0.1", subnet: "255.255.255.0",
            dns: "8.8.8.8", mtu: 1024
        )
    }

    private struct UserConfiguration: Codable { }

    private struct Request: Codable { }

    private class ProviderImplementation: TMPacketTunnelProvider {

        required init() {

        }

        func configureTunnel(
            userConfigurationData: Data?,
            settingsApplicationBlock: @escaping (NETunnelNetworkSettings?, ((Error?) -> Void)?) -> Void,
            completionHandler: @escaping (TMTunnelConfigurationError?) -> Void
        ) {
            TMMockTunnelProviderManagerTests.configurationInvocation.fulfill()
            completionHandler(nil)
        }

        func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
            completionHandler(nil)
        }

        func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {

        }

        func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
            TMMockTunnelProviderManagerTests.appMessageHandlerInvocation.fulfill()
        }

    }

    override func setUp() {
        TunnelMonitorKit.loggers = [TMBasicLogger()]

        Self.configurationInvocation = XCTestExpectation(description: "Provider configuration invoked")
        Self.appMessageHandlerInvocation = XCTestExpectation(description: "App message received")
    }

    func testConfigurationInvokedWhenStarted() {
        let mockProviderManager = try? TMMockTunnelProviderManager(
            provider: ProviderImplementation(),
            networkSettings: networkSettings,
            userConfiguration: UserConfiguration()
        )

        mockProviderManager?.startTunnel()

        wait(for: [Self.configurationInvocation], timeout: 0.5)
    }

    func testAppMessageNotReceivedIfNotStarted() {
        let mockProviderManager = try? TMMockTunnelProviderManager(
            provider: ProviderImplementation(),
            networkSettings: networkSettings,
            userConfiguration: UserConfiguration()
        )

        mockProviderManager?.send(message: "Hello")

        Self.appMessageHandlerInvocation.isInverted = true
        wait(for: [Self.appMessageHandlerInvocation], timeout: 0.5)

    }

    func testAppMessageReceived() {
        let mockProviderManager = try? TMMockTunnelProviderManager(
            provider: ProviderImplementation(),
            networkSettings: networkSettings,
            userConfiguration: UserConfiguration()
        )

        mockProviderManager?.startTunnel()
        mockProviderManager?.send(message: "Hello")

        wait(for: [Self.appMessageHandlerInvocation], timeout: 0.5)
    }
}

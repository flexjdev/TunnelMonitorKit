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
            includedRoutes: "255.255.255.255:0.0.0.0", excludedRoutes: "0.0.0.0:0.0.0.0",
            tunnelAddress: "10.0.0.1", subnet: "255.255.255.0",
            dns: "8.8.8.8", mtu: 1024
        )
    }

    private struct UserConfiguration: Codable { }

    private struct Request: Codable { }

    /// A mock provider implementation used to test the mock tunnel provider manager
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
            log(.info, "Stopped tunnel provider with reason: \(reason)")
            completionHandler()
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

    func testReturnsCorrectStatus() throws {
        let mockProviderManager = try TMTunnelProviderManagerFactory.createMockProviderManager(
            ofType: ProviderImplementation.self,
            networkSettings: networkSettings,
            userConfiguration: UserConfiguration()
        )

        XCTAssertNotEqual(mockProviderManager.tunnelStatus, .connected)
        mockProviderManager.startTunnel()
        XCTAssertEqual(mockProviderManager.tunnelStatus, .connected)
    }

    func testConfigurationInvokedWhenStarted() {
        let mockProviderManager = try? TMTunnelProviderManagerFactory.createMockProviderManager(
            ofType: ProviderImplementation.self,
            networkSettings: networkSettings,
            userConfiguration: UserConfiguration()
        )

        mockProviderManager?.startTunnel()

        wait(for: [Self.configurationInvocation], timeout: 0.5)
    }

    func testAppMessageNotReceivedIfNotStarted() {
        let mockProviderManager = try? TMTunnelProviderManagerFactory.createMockProviderManager(
            ofType: ProviderImplementation.self,
            networkSettings: networkSettings,
            userConfiguration: UserConfiguration()
        )

        mockProviderManager?.send(message: "Hello")

        Self.appMessageHandlerInvocation.isInverted = true
        wait(for: [Self.appMessageHandlerInvocation], timeout: 0.5)

    }

    func testAppMessageReceived() {
        let mockProviderManager = try? TMTunnelProviderManagerFactory.createMockProviderManager(
            ofType: ProviderImplementation.self,
            networkSettings: networkSettings,
            userConfiguration: UserConfiguration()
        )

        mockProviderManager?.startTunnel()
        mockProviderManager?.send(message: "Hello")

        wait(for: [Self.appMessageHandlerInvocation], timeout: 0.5)
    }

    func testMonitoringNotStartedIfTunnelNotStarted() throws {
        let mockProviderManager = try TMTunnelProviderManagerFactory.createMockProviderManager(
            ofType: ProviderImplementation.self,
            networkSettings: networkSettings,
            userConfiguration: UserConfiguration()
        )

        mockProviderManager.startMonitoring(
            withRequestBuilder: { Request() },
            responseHandler: { (_: Result<Data, TMCommunicationError>) in }
        )

        Self.appMessageHandlerInvocation.isInverted = true
        wait(for: [Self.appMessageHandlerInvocation], timeout: 0.5)
    }

    func testMonitoringStartedSuccessfully() throws {
        let mockProviderManager = try TMTunnelProviderManagerFactory.createMockProviderManager(
            ofType: ProviderImplementation.self,
            networkSettings: networkSettings,
            userConfiguration: UserConfiguration()
        )

        mockProviderManager.startTunnel()
        mockProviderManager.startMonitoring(
            withRequestBuilder: { Request() },
            responseHandler: { (_: Result<Data, TMCommunicationError>) in }
        )

        wait(for: [Self.appMessageHandlerInvocation], timeout: 0.5)
    }
}

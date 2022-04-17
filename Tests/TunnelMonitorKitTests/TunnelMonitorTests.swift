//
//  TunnelMonitorTests.swift
//  TunnelMonitorKit
//
//  Created by Chris J on 18/04/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import XCTest
@testable import TunnelMonitorKit

final class TunnelMonitorTests: XCTestCase {

    struct Request: Codable { }

    func testMonitorSendsRequestImmediatelyWhenStarted() {
        var handlerInvoked = false

        let mockSession = TMTunnelProviderSessionMock()
        try? mockSession.startTunnel(options: nil)
        mockSession.mockMessageRouter.addHandler({ _, _ in handlerInvoked = true }, for: Request.self)

        let monitor = TunnelMonitor()
        monitor.setSession(session: mockSession)

        monitor.startMonitoring(
            withRequestBuilder: { Request() },
            pollInterval: 10.0
        )

        XCTAssert(handlerInvoked)
    }

    func testMonitorSendsRepeatedRequests() {
        let handlerInvocation = XCTestExpectation(description: "Status request handler invoked")
        handlerInvocation.expectedFulfillmentCount = 2

        let mockSession = TMTunnelProviderSessionMock()
        try? mockSession.startTunnel(options: nil)
        mockSession.mockMessageRouter.addHandler({ _, _ in handlerInvocation.fulfill() }, for: Request.self)

        let monitor = TunnelMonitor()
        monitor.setSession(session: mockSession)

        monitor.startMonitoring(
            withRequestBuilder: { Request() },
            pollInterval: 0.1
        )

        wait(for: [handlerInvocation], timeout: 1.0)
    }

    func testMonitorStopsSendingRequestsWhenStopped() {
        let handlerInvocation = XCTestExpectation(description: "Status request handler invoked")
        handlerInvocation.expectedFulfillmentCount = 1
        handlerInvocation.assertForOverFulfill = true

        let mockSession = TMTunnelProviderSessionMock()
        try? mockSession.startTunnel(options: nil)
        mockSession.mockMessageRouter.addHandler({ _, _ in handlerInvocation.fulfill() }, for: Request.self)

        let monitor = TunnelMonitor()
        monitor.setSession(session: mockSession)

        monitor.startMonitoring(
            withRequestBuilder: { Request() },
            pollInterval: 0.1
        )
        monitor.stopMonitoring()

        wait(for: [handlerInvocation], timeout: 1.0)
    }

    func testMonitorNotInvokedWhenDisconnected() {
        var handlerInvoked = false

        let mockSession = TMTunnelProviderSessionMock()
        mockSession.setStatus(.disconnected)
        mockSession.mockMessageRouter.addHandler({ _, _ in handlerInvoked = true }, for: Request.self)

        let monitor = TunnelMonitor()
        monitor.setSession(session: mockSession)

        monitor.startMonitoring(
            withRequestBuilder: { Request() },
            pollInterval: 0.1
        )

        XCTAssertFalse(handlerInvoked)
    }
}

//
//  TunnelMonitorTests.swift
//  TunnelMonitorKit
//
//  Created by Chris J on 18/04/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import XCTest
import NetworkExtension
@testable import TunnelMonitorKit

/// Tests the logic around error handling in TunnelMonitor and additionally tests some logic in the mock session,
/// increasing confidence in how reliably it can be used for mocks in apps using this framework.
final class TunnelMonitorTests: XCTestCase {

    struct Request: Codable { }
    struct Response: Codable { }

    var mockSession: TMTunnelProviderSessionMock!
    var handlerInvocation: XCTestExpectation!
    var responseReceived: XCTestExpectation!
    var sendFailure: XCTestExpectation!
    var monitor: TunnelMonitor!

    override func setUp() {
        TunnelMonitorKit.loggers = [TMBasicLogger()]

        mockSession = TMTunnelProviderSessionMock()
        handlerInvocation = XCTestExpectation(description: "Status request handler invoked")
        responseReceived = XCTestExpectation(description: "Response received")
        sendFailure = XCTestExpectation(description: "Send failure")
        monitor = TunnelMonitor()

        guard let response = try? JSONEncoder().encode(Response()) else {
            XCTFail("Failed to serialize sample response message for TunnelMonitor tests.")
            return
        }
        let statusRequestHandler: MessageHandler = { _, responseHandler in responseHandler?(response) }
        mockSession.mockMessageRouter.addHandler(statusRequestHandler, for: Request.self)

        try? mockSession.startTunnel(options: nil)

        XCTAssertEqual(mockSession.status, .connected, "Failed to start tunnel")
    }

    override func tearDown() {
        super.tearDown()
        mockSession = nil
        handlerInvocation = nil
        monitor = nil
    }

    /// Convenience function for setting up monitoring. It sets up a default handler to fulfill the handlerInvocation
    /// expectation, and optionally a custom completion handler.
    /// - Parameters:
    ///   - customHandler: Custom completion handler for status updates.
    ///   - interval: interval at which the monitor should poll the session.
    func startMonitoring(
        interval: TimeInterval,
        withUpdateHandler customHandler: ((Result<Response, TMCommunicationError>) -> Void)? = nil
    ) {
        let handler = { (result: Result<Response, TMCommunicationError>) in
            self.handlerInvocation?.fulfill()
            switch result {
            case .success: self.responseReceived.fulfill()
            case .failure: self.sendFailure.fulfill()
            }
            customHandler?(result)
        }

        monitor.startMonitoring(
            session: mockSession,
            withRequestBuilder: { Request() },
            responseHandler: handler,
            pollInterval: interval
        )
    }

    func testMockSessionSetupCorrectly() {
        XCTAssertEqual(mockSession.status, .connected)
    }

    // MARK: message tests

    func testInvalidExtensionErrorWhenSessionNil() {
        monitor.setSession(session: nil)

        monitor.send(message: Request()) { (result: Result<Response, TMCommunicationError>) in
            self.handlerInvocation.fulfill()

            switch result {
            case .success: XCTFail("A response should not be received when session is nil.")
            case .failure(let error):
                guard case .invalidExtension = error else {
                    XCTFail("Monitor should return invalid extension error when session is nil.")
                    return
                }
            }
        }

        wait(for: [handlerInvocation], timeout: 0.5)
    }

    func testInvalidStateErrorWhenNotConnected() {
        let sessionState: NEVPNStatus = .disconnected
        mockSession.setStatus(sessionState)
        monitor.setSession(session: mockSession)

        monitor.send(message: Request()) { (result: Result<Response, TMCommunicationError>) in
            self.handlerInvocation.fulfill()

            switch result {
            case .success:
                XCTFail("A response should not be received when session is nil.")
            case .failure(let error):
                guard case .invalidState(let state) = error else {
                    XCTFail("Monitor should return invalid extension error when session is nil: \(error)")
                    return
                }
                XCTAssertEqual(state, sessionState)
            }
        }

        wait(for: [handlerInvocation], timeout: 0.5)
    }

    func testResponseReceivedWhenSessionConnected() {
        let sessionState: NEVPNStatus = .connected
        mockSession.setStatus(sessionState)
        monitor.setSession(session: mockSession)

        monitor.send(message: Request()) { (result: Result<Response, TMCommunicationError>) in
            self.handlerInvocation.fulfill()

            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Monitor should return response when requesting and sesion is connected \(error)")
            }
        }

        wait(for: [handlerInvocation], timeout: 0.5)
    }

    // MARK: scheduled request tests

    func testMonitorSendsRequestImmediatelyWhenStarted() {
        startMonitoring(interval: 0.1)

        wait(for: [responseReceived], timeout: 1.0)
    }

    func testMonitorSendsRepeatedRequests() {
        responseReceived.expectedFulfillmentCount = 2

        startMonitoring(interval: 0.1)

        wait(for: [responseReceived], timeout: 1.0)
    }

    func testMonitorStopsSendingRequestsWhenStopped() {
        responseReceived.expectedFulfillmentCount = 1
        responseReceived.assertForOverFulfill = true

        startMonitoring(interval: 0.1)
        monitor.stopMonitoring()

        wait(for: [responseReceived], timeout: 1.0)
    }

    // MARK: Error path tests

    func testCorrectErrorWhenSessionSendInInvalidState() throws {
        monitor.setSession(session: mockSession)

        NEVPNStatus.allCases.forEach { state in
            let errorExpectation = XCTestExpectation(description: "Tunnel monitor should return invalid state error")

            mockSession.setStatus(state)
            monitor.send(message: Request()) { (result: Result<Response, TMCommunicationError>) in
                switch result {
                case .success:
                    XCTAssertEqual(state, .connected, "Send message not succeed when the session is in state \(state)")
                case .failure(let error):
                    guard case .invalidState(let errorState) = error else {
                        return XCTFail("Expected invalid state error but got \(error)")
                    }
                    XCTAssertEqual(errorState, state)
                }
                errorExpectation.fulfill()
            }
            wait(for: [errorExpectation], timeout: 0.5)
        }
    }
}

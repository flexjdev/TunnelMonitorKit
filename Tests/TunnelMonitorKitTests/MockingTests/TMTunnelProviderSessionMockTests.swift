//
//  TMTunnelProviderSessionMockTests.swift
//  TunnelMonitorKit
// 
//  Created by Chris J on 25/05/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation
import NetworkExtension
import XCTest
@testable import TunnelMonitorKit

final class TMTunnelProviderSessionMockTests: XCTestCase {

    private struct Request: Codable { }

    private var requestData: Data {
        guard
            let message = try? MessageContainer.make(message: Request()),
            let data = try? JSONEncoder().encode(message)
        else {
            XCTFail("Failed to send message to mock session - error serializing test message")
            return Data()
        }
        return data
    }

    func testReportsCorrectStatus() {
        let mockSession = TMTunnelProviderSessionMock()

        NEVPNStatus.allCases.forEach { status in
            mockSession.setStatus(status)
            XCTAssertEqual(mockSession.status, status)
        }
    }

    func testSendMessageSucceedsWhenConnected() {

        let mockSession = TMTunnelProviderSessionMock()
        mockSession.setStatus(.connected)

        do {
            try mockSession.sendProviderMessage(requestData) { _ in }
        } catch {
            XCTFail("Failed to send message to mock session: \(error)")
        }
    }

    func testSendMessageFailsWhenNotConnected() throws {
        let mockSession = TMTunnelProviderSessionMock()
        try NEVPNStatus.allCases.filter { $0 != .connected }.forEach { status in
            mockSession.setStatus(status)
            XCTAssertThrowsError(try mockSession.sendProviderMessage(requestData, responseHandler: { _ in })) { error in
                guard case TMCommunicationError.invalidState(let errorStatus) = error else {
                    return XCTFail("Incorrect error type returned \(error)")
                }
                XCTAssertEqual(errorStatus, status)
            }
        }
    }

    func testSendMessageFailsWhenGarbageDataSent() {
        let emptyData = Data()

        let mockSession = TMTunnelProviderSessionMock()
        mockSession.setStatus(.connected)
        XCTAssertThrowsError(try mockSession.sendProviderMessage(emptyData, responseHandler: { _ in })) { error in
            guard case TMCommunicationError.responseDecodingError = error else {
                return XCTFail("Incorrect error type returned \(error)")
            }
        }
    }

}

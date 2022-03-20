//
//  MessageRouterTests.swift
//  TunnelMonitorKit
// 
//  Created by Chris J on 19/03/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import XCTest
@testable import TunnelMonitorKit

final class MessageRouterTests: XCTestCase {

    struct MessageTypeA: Codable { }
    struct MessageTypeB: Codable { }

    func testHandlerInvokedForRelatedMessageType() throws {
        let router = MessageRouter()

        var messageHandlerAInvoked = false
        var messageHandlerBInvoked = false
        let messageHandlerA: MessageHandler = { _, _ in messageHandlerAInvoked = true }
        let messageHandlerB: MessageHandler = { _, _ in messageHandlerBInvoked = true }

        router.addHandler(messageHandlerA, for: MessageTypeA.self)
        router.addHandler(messageHandlerB, for: MessageTypeB.self)

        let message = MessageContainer(
            metatype: String(describing: MessageTypeA.self),
            content: try JSONEncoder().encode(MessageTypeA())
        )

        let handlersInvoked = router.handle(message: message, completionHandler: nil)

        XCTAssert(handlersInvoked == 1)
        XCTAssert(messageHandlerAInvoked)
        XCTAssert(!messageHandlerBInvoked)
    }

    func testMultipleHandlersInvokedForSingleMessageType() throws {
        let router = MessageRouter()

        var messageHandler1Invoked = false
        var messageHandler2Invoked = false
        let messageHandler1: MessageHandler = { _, _ in messageHandler1Invoked = true }
        let messageHandler2: MessageHandler = { _, _ in messageHandler2Invoked = true }

        router.addHandler(messageHandler1, for: MessageTypeA.self)
        router.addHandler(messageHandler2, for: MessageTypeA.self)

        let message = MessageContainer(
            metatype: String(describing: MessageTypeA.self),
            content: try JSONEncoder().encode(MessageTypeA())
        )

        let handlersInvoked = router.handle(message: message, completionHandler: nil)

        XCTAssert(handlersInvoked == 2)
        XCTAssert(messageHandler1Invoked)
        XCTAssert(messageHandler2Invoked)
    }

}

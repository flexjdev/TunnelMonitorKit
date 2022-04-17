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

    var router: MessageRouter!

    var messageHandlerAInvoked: Bool!
    var messageHandlerBInvoked: Bool!

    var messageHandlerA: MessageHandler!
    var messageHandlerB: MessageHandler!

    struct MessageTypeA: Codable { }
    struct MessageTypeB: Codable { }

    override func setUp() {
        router = MessageRouter()

        messageHandlerAInvoked = false
        messageHandlerBInvoked = false

        messageHandlerA = { _, _ in self.messageHandlerAInvoked = true }
        messageHandlerB = { _, _ in self.messageHandlerBInvoked = true }
    }

    func testRouterHandlersReturnsCorrectSizeArray() {
        XCTAssertEqual(router.handlers(for: MessageTypeA.self).count, 0)

        router.addHandler(messageHandlerA, for: MessageTypeA.self)
        XCTAssertEqual(router.handlers(for: MessageTypeA.self).count, 1)

        router.addHandler(messageHandlerB, for: MessageTypeA.self)
        XCTAssertEqual(router.handlers(for: MessageTypeA.self).count, 2)
    }

    func testRouterHandlersRemovedForMessageType() {
        XCTAssertEqual(router.handlers(for: MessageTypeA.self).count, 0)

        router.addHandler(messageHandlerA, for: MessageTypeA.self)
        router.addHandler(messageHandlerB, for: MessageTypeB.self)
        XCTAssertEqual(router.handlers(for: MessageTypeA.self).count, 1)
        XCTAssertEqual(router.handlers(for: MessageTypeB.self).count, 1)

        router.removeHandlers(for: MessageTypeA.self)
        XCTAssertEqual(router.handlers(for: MessageTypeA.self).count, 0)
        XCTAssertEqual(router.handlers(for: MessageTypeB.self).count, 1)
    }

    func testHandlerInvokedForRelatedMessageType() throws {
        router.addHandler(messageHandlerA, for: MessageTypeA.self)
        router.addHandler(messageHandlerB, for: MessageTypeB.self)

        let message = MessageContainer.make(message: MessageTypeA())!

        let numHandlersInvoked = router.handle(message: message, completionHandler: nil)

        XCTAssertEqual(numHandlersInvoked, 1)
        XCTAssert(messageHandlerAInvoked)
        XCTAssertFalse(messageHandlerBInvoked)
    }

    func testMultipleHandlersInvokedForSingleMessageType() throws {
        router.addHandler(messageHandlerA, for: MessageTypeA.self)
        router.addHandler(messageHandlerB, for: MessageTypeA.self)

        let message = MessageContainer.make(message: MessageTypeA())!

        let numHandlersInvoked = router.handle(message: message, completionHandler: nil)

        XCTAssertEqual(numHandlersInvoked, 2)
        XCTAssert(messageHandlerAInvoked)
        XCTAssert(messageHandlerBInvoked)
    }

    func testHandlerNotInvokedAfterBeingRemoved() throws {
        router.addHandler(messageHandlerA, for: MessageTypeA.self)
        router.removeHandlers(for: MessageTypeA.self)

        let message = MessageContainer.make(message: MessageTypeA())!

        let numHandlersInvoked = router.handle(message: message, completionHandler: nil)

        XCTAssertEqual(numHandlersInvoked, 0)
        XCTAssertFalse(messageHandlerAInvoked)
    }

}

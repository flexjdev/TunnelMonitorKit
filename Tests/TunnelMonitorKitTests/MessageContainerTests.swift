//
//  MessageContainerTests.swift
//  TunnelMonitorKit
// 
//  Created by Chris J on 20/03/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation

import XCTest
@testable import TunnelMonitorKit

final class MessageContainerTests: XCTestCase {

    struct MessageTypeA: Codable { }
    struct MessageTypeB: Codable, Equatable {
        let string: String
    }

    func testMetatypeStringRepresentationNotEqual() throws {
        XCTAssertNotEqual(String.metatype(from: MessageTypeA.self), String.metatype(from: MessageTypeB.self))
    }

    func testCanDecodeMessageContainer() throws {
        let message = MessageContainer(
            metatype: String(describing: MessageTypeA.self),
            content: try JSONEncoder().encode(MessageTypeA())
        )

        let messageData = try JSONEncoder().encode(message)

        let decodedMessage = try JSONDecoder().decode(MessageTypeA.self, from: messageData)

        XCTAssertNotNil(decodedMessage)
    }

    func testDecodedMessageContentsPreserved() throws {
        let messageContent = MessageTypeB(string: "test")

        let message = MessageContainer(
            metatype: String(describing: MessageTypeB.self),
            content: try JSONEncoder().encode(messageContent)
        )

        let messageData = try JSONEncoder().encode(message)
        let decodedMessage = try JSONDecoder().decode(MessageContainer.self, from: messageData)

        XCTAssertNotNil(decodedMessage.content)
        let decodedContent = try JSONDecoder().decode(MessageTypeB.self, from: decodedMessage.content ?? Data())

        XCTAssertEqual(messageContent, decodedContent)
    }
}

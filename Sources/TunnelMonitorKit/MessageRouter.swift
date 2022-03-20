//
//  MessageRouter.swift
//  TunnelMonitorKit
// 
//  Created by Chris J on 19/03/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation

/// Represents the action performed to optionally send data in response to a message.
public typealias ResponseCompletion = ((Data?) -> Void)?

/// Function signature for handling and responding to a message.
public typealias MessageHandler = ((Data?, ResponseCompletion) -> Void)

/// Responsible for registering callbacks to handle receiving specific message types.
public class MessageRouter {

    /// Mapping of a message Metatype's string representation to an array of handler functions.
    private var handlerMap: [String: [MessageHandler]] = [:]

    public init() { }

    /// Register a handler for the given message content type.
    /// - Parameters:
    ///   - handler: A block that handles the message and optionally replies using the response completion
    ///   - messageType: The message content type this handler should be invoked for
    public func addHandler(_ handler: @escaping MessageHandler, for messageType: Codable.Type) {
        let metatypeString = String.metatype(from: messageType)
        let handlers = handlerMap[metatypeString] ?? []
        handlerMap[metatypeString] = handlers + [handler]
    }

    /// Returns all message handlers currently associated with a message type.
    /// - Parameter messageType: The message type to find handlers for
    /// - Returns: All message handlers associated with the given message type
    public func handlers(for messageType: Codable.Type) -> [MessageHandler] {
        let metatypeString = String.metatype(from: messageType)
        return handlerMap[metatypeString] ?? []
    }

    /// Removes all handlers for a particular message type.
    /// - Parameter messageType: The message type to remove handlers for
    public func removeHandlers(for messageType: Codable.Type) {
        let metatypeString = String.metatype(from: messageType)
        handlerMap[metatypeString] = []
    }

    /// Invokes all handlers associated with the content type of the given message
    /// - Parameters:
    ///   - message: The incoming message
    ///   - completionHandler: Responds to the message sender using the given data
    /// - Returns: Number of handlers invoked
    public func handle(message: MessageContainer, completionHandler: ResponseCompletion) -> Int {
        guard let handlers = handlerMap[message.metatype], !handlers.isEmpty else {
            return 0
        }
        handlers.forEach { handler in handler(message.content, completionHandler) }
        return handlers.count
    }
}

//
//  MessageRouter.swift
//  TunnelMonitorKit
// 
//  Created by Chris J on 19/03/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation

typealias ResponseCompletion = ((Data?) -> Void)?
typealias MessageHandler = ((Data?, ResponseCompletion) -> Void)

/// Responsible for registering callbacks to handle receiving specific message types.
class MessageRouter {

    /// Mapping of a message Metatype's string representation to an array of handler functions
    private var handlerMap: [String: [MessageHandler]] = [:]

    /// Register a handler for the given message content type
    /// - Parameters:
    ///   - handler: A block that handles the message and optionally replies using the response completion
    ///   - messageType: The message content type this handler should be invoked for
    func addHandler(_ handler: @escaping MessageHandler, for messageType: Codable.Type) {
        let metatypeString = String(describing: messageType)
        let handlers = handlerMap[metatypeString] ?? []
        handlerMap[metatypeString] = handlers + [handler]
    }

    /// Invokes all handlers associated with the content type of the given message
    /// - Parameters:
    ///   - message: The incoming message
    ///   - completionHandler: Responds to the message sender using the given data
    /// - Returns: Number of handlers invoked
    func handle(message: MessageContainer, completionHandler: ResponseCompletion) -> Int {
        guard let handlers = handlerMap[message.metatype], !handlers.isEmpty else {
            return 0
        }
        handlers.forEach { handler in handler(message.content, completionHandler) }
        return handlers.count
    }
}

struct MessageContainer: Codable {
    let metatype: String
    let content: Data?
}

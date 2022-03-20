//
//  MessageContainer.swift
//  TunnelMonitorKit
// 
//  Created by Chris J on 20/03/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation

/// A wrapper/container struct used to transfer codable structs across processes. Wrapping the message content in
/// another struct allows the container to carry metadata indicating the type of the content. This informs the receiver
/// of the type information, allowing them to decode it more easily.
/// Serialisation has been implemented using Codable for simplicity, but this could be abstracted out or replaced with
/// a more sophisticated serialisation strategy in the future.
public struct MessageContainer: Codable {

    /// A string representation of the metatype of the message content.
    let metatype: String

    /// Serialised representation of the message content.
    let content: Data?


    /// Initialises a Message container.
    /// - Parameters:
    ///   - metatype: The metatype of the message content
    ///   - content: Serialised representation of the message content
    public init(messageType: Codable.Type, content: Data?) {
        self.metatype = String.metatype(from: messageType)
        self.content = content
    }

    /// Attempts to decode a MessageContrainer from serialised data.
    /// - Parameter data: The data to deserialise
    /// - Returns: A decoded MessageContainer, or nil if the data was invalid
    static func decode(from data: Data) -> MessageContainer? {
        do {
            return try JSONDecoder().decode(self, from: data)
        } catch {
            return nil
        }
    }

}

public extension String {

    /// Returns a unique string representation of a given Codable metatype.
    /// - Parameter type: Metatype of an object conforming to Codable
    /// - Returns: A unique string representation of a given Codable metatype
    static func metatype(from type: Codable.Type) -> String {
        return String(describing: type)
    }
}

//
//  TMCommunicationError.swift
//  TunnelMonitorKit
//
//  Created by Chris J on 18/04/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import NetworkExtension

/// Contains information about why communication with tunnel failed
public enum TMCommunicationError: Error {

    /// The extension is not in a state in which it can be communicated with
    case invalidState(NEVPNStatus)

    /// The manager connection instance could not be cast to a NETunnelProviderSession or is nil
    case invalidExtension

    /// The response received was nil
    case nilResponse

    /// The response could not be decoded
    case responseDecodingError(decodeError: Error)

    /// The outgoing message could not be serialized
    case containerSerializationError(encodeError: Error)

    /// Generic error sending message
    case sendFailure(error: Error)
}

extension TMCommunicationError: CustomStringConvertible {

    /// Provides a meaningful description for each error type
    public var description: String {
        switch self {
        case .invalidState(let status):
            return "The extension is not in a state in which it can be communicated with: \(status)."
        case .invalidExtension:
            return "The extension is of incorrect type or nil - it could not be cast to a NETunnelProviderSession."
        case .nilResponse:
            return "The extension response was nil."
        case .responseDecodingError(let error):
            return "Failed to decode response: \(error)"
        case .containerSerializationError(let error):
            return "Failed to serialize outgoing message: \(error)"
        case .sendFailure(let error):
            return "Failed to send message: \(error)"
        }
    }

}

# TunnelMonitorKit

![Build status badge](https://github.com/chrisjanusiewicz/TunnelMonitorKit/actions/workflows/ci.yml/badge.svg)
[![codecov](https://codecov.io/gh/ChrisJanusiewicz/TunnelMonitorKit/branch/master/graph/badge.svg?token=SI8AY4N5PS)](https://codecov.io/gh/ChrisJanusiewicz/TunnelMonitorKit)
[![MIT License badge](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

TunnelMonitorKit is a Swift package designed to streamline IPC, for example for an App's communication with its `NEPacketTunnelProvider` network extension.

# Why?

Implementing for IPC (Inter-Process Communication) can be a lengthy, verbose and error-prone task.
The aim of TunnelMonitorKit is to simplify this process by providing a solid structure for implementing IPC between two process such as the host application and its `NEPacketTunnelProvider` or `NEAppProxyProvider` app extension.

The example usage shows how to integrate TunnelMonitorKit with a network extension but the concept can be abstracted out and applied to other sets of processes that need to communicate with each other.

## Constraints

The concrete message passing implementation is aimed to be used with network extension APIs, allowing the host app to send a request to the app extension.
The app extension can optionally send a response to this request using the given completion handler.
This means that for this particular use case, the communication can only be reliably initiated by the host app - although the app can regularly probe the extension for updates.

```swift
NETunnelProviderSession.sendProviderMessage(_ messageData: Data, responseHandler: ((Data?) -> Void)? = nil) throws
NETunnelProvider.handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil)
```

# Usage

`MessageRouter` can handle messages defined by any struct that implements `Codable`.
These messages are wrapped by a `MessageContainer` which carries the information about the type of the message content.
As long as your message types conform to this protocol, they can be sent and received and automatically routed to whichever handler has been assigned to that particular message type.
It is up to the handler to decode the serialised message content into the correct type.

```swift
let stateRequestHandler = { (data: Data?, completion: ResponseCompletion) -> Void in
    // Decode message request
    let message = try! JSONDecoder().decode(StateRequest.self, from: data!)
    
    // Form a response
    let responseData = JSONEncoder().encode(StateResponse(...))
    
    // Pass it to the ResponseCompletion handler
    completion?(responseData)
}
```

In the network extension use case, the class overriding `NEPacketTunnelProvider` should define a `MessageRouter`, and register message handlers for each type of message that may be received.

```swift
let router = MessageRouter()
router.addHandler(stateRequestHandler, for: StateRequest.self)
```

Actual message data will be received by the `NEPacketTunnelProvider` superclass through `handleAppMessage`, and it should be passed to the router, which will invoke the correct handler depending on the type of the message contents.
The `completionHandler` parameter is used to send a response back to the host app - this is the `ResponseCompletion` part of each handler you define.

```swift
override open func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
      let request = try! JSONDecoder().decode(MessageContainer.self, from: messageData)
      _ = router.handle(message: request, completionHandler: handler)
}
```

## Logging

For debugging purposes, logging can be enabled by appending an instance of `TMLogger` to `TunnelMonitorKit.loggers`.
`TMLogger` is a protocol which can be implemented by custom logger implementations based on existing logging frameworks.
`TMOSLogger` is a sample implementation based on the unified system logger.
It also distinguishes logs originating from the host application and network extension.

```swift
let logger = TMOSLogger()
logger.setLogLevel(.warning)
TunnelMonitorKit.loggers.append(logger)
```

# Dependencies

Distributed through Swift Package Manager. No external dependencies at this point in time.


# License

TunnelMonitorKit is released under the MIT license. See [LICENSE.md](LICENSE.md) for details.

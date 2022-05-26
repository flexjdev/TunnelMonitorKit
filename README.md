# TunnelMonitorKit

![Build status badge](https://github.com/chrisjanusiewicz/TunnelMonitorKit/actions/workflows/ci.yml/badge.svg)
[![codecov](https://codecov.io/gh/ChrisJanusiewicz/TunnelMonitorKit/branch/master/graph/badge.svg?token=SI8AY4N5PS)](https://codecov.io/gh/ChrisJanusiewicz/TunnelMonitorKit)
[![MIT License badge](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

TunnelMonitorKit is a Swift package designed to streamline IPC, for example for an App's communication with its `NEPacketTunnelProvider` network extension.
It also defines a framework for mocking packet tunnel providers, allowing network extension logic to be executed and tested in the app layer.
This allows packet tunnel provider implementations to also be executed on simulator target environments.

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
    router.handle(message: request, completionHandler: handler)
}
```

## Mocking

`TunnelMonitorKit` allows for a single packet tunnel provider implementation to be executed as a tunnel provider on network extension targets, as well as in the container app target.
This allows the tunnel provider implementation to be mocked and tested when deploying to simulator target environments.
Limitations include not having access to the packetFlow object when mocking, making actual VPN implementations near impossible when running in the app layer.

`TMPacketTunnelProvider` must be a protocol, as instances of `NEPacketTunnelProvider` and its subclasses cannot be instantiated on non-network extension targets, while a native packet tunnel provider must inherit from this class in order to be instantiated by the system.
The workaround is to define a generic subclass of a class that implements the provider protocol for running on network extension targets (`TMPacketTunnelProviderNative<T: TMPacketTunnelProvider>`), and create a class that inherits from the same provider protocol implementation for mocking (`TMMockTunnelProviderManager`).
This allows a single implementation to instantiated on, and outside network extension targets.

### Sample Usage

Firstly, instead of defining your network service logic by subclassing `NEPacketTunnelProvider`, implement the `TMPacketTunnelProvider` protocol.

```swift
public class MyTunnelProvider: TMPacketTunnelProvider {

    required init() {
        // Peform any setup that doesn't require user configuration
        // Register any necessary message handlers using a `MessageRouter` in order to take advantage of `TunnelMonitor` functionality
    }

    func configureTunnel(
        userConfigurationData: Data?,
        settingsApplicationBlock: @escaping (NETunnelNetworkSettings?, ((Error?) -> Void)?) -> Void,
        completionHandler: @escaping (TMTunnelConfigurationError?) -> Void
    ) {
        // If special configuration is required, decode it from `userConfigurationData`.
        // Call the completion handler once the tunnel has been configured.
    }

    func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Start the service (asynchronously if necessary) and call the completion handler when finished.
    }

    func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Perform any cleanup actions, stop the service and call the completion handler.
    }

    func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Decode the request from `messageData` and pass the request to a `MessageRouter` to respond using the correct message handler
    }

}
```

You must then subclass `TMPacketTunnelProviderNative` constraining generic `TunnelProvider` to your implementation of the `TMPacketTunnelProvider` protocol.

```swift
open class MyNativeTunnelProvider: TMPacketTunnelProviderNative<MyTunnelProvider> { }
```

The Packet Tunnel target must still define a `TMPacketTunnelProviderNative` subclass constrained to an implementation of the `TMPacketTunnelProvider` protocol, with the info.plist file pointing to it via the `NSExtensionPrincipalClass` entry.

### Starting Mocked/Native Tunnels

Use `TMTunnelProviderManagerFactory` to instantiate/load mock and native tunnels.
Compiler directives can be used to automatically force mocked tunnel providers to be created when building for simulator target environments.

```swift
func loadProviderManager<UserConfiguration: Codable, ProviderType: TMPacketTunnelProvider>(
      ofType type: ProviderType.Type,
      completionHandler: @escaping (TMTunnelProviderManager?) -> Void
) {
#if targetEnvironment(simulator)
    completionHandler(try? TMTunnelProviderManagerFactory.createMockProviderManager(...))
#else
    TMTunnelProviderManagerFactory.loadNativeProviderManager(...) { providerManager in
        completionHandler(providerManager)
    }
#endif
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

Distributed through Swift Package Manager.
No external dependencies at this point in time.

# License

TunnelMonitorKit is released under the MIT license. See [LICENSE.md](LICENSE.md) for details.

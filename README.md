# TunnelMonitorKit

![Swift build status badge](https://github.com/chrisjanusiewicz/TunnelMonitorKit/actions/workflows/swift.yml/badge.svg)
[![MIT License badge](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

TunnelMonitorKit is a Swift package designed to streamline an App's communication with `NEPacketTunnelProvider` and `NEAppProxyProvider` network extensions.

# Why?

Implementing for IPC (Inter-Process Communication) can be a lengthy, verbose and error-prone task.
The aim of TunnelMonitorKit is to simplify this process by providing a solid structure for implementing IPC between the host application and its `NEPacketTunnelProvider` or `NEAppProxyProvider` app extension.

The network extension type constraint is based on the concrete implementation of message passing provided by `NETunnelProvider`, but the concept can be abstracted out and applied to other types of extensions.

## Constraints

The concrete message passing implementation is based on the following network extension APIs, allowing the host app to send a request to the app extension.
The app extension can optionally send a response to this request using the given completion handler.
This means the communication can only be reliably initiated by the host app - although the app can regularly probe the extension for updates.

`NETunnelProviderSession.sendProviderMessage(_ messageData: Data, responseHandler: ((Data?) -> Void)? = nil) throws`
`NETunnelProvider.handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil)`

# Usage

# Dependencies

# License

TunnelMonitorKit is released under the MIT license. See [LICENSE.md](LICENSE.md) for details.

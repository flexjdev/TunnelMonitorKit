//
//  TMExtensionManager.swift
//  TunnelMonitorKit
//
//  Created by Chris J on 13/05/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation
import NetworkExtension

public protocol TMExtensionManagerDelegate: TMTunnelProviderManagerDelegate { }

extension TMExtensionManager: TMTunnelProviderManagerDelegate {

    public func tunnelStateChanged(to state: NEVPNStatus) {
        delegate?.tunnelStateChanged(to: state)
    }

    public func serviceStateChanged<T: Codable>(manager: TMExtensionManager<T>, to state: T) {
        guard let state = state as? ServiceInfo else {
            log(.error, "Incorrect state passed from provider")
            return
        }
        delegate?.serviceStateChanged(manager: self, to: state)
    }

}
public class TMExtensionManager<ServiceInfo: Codable> {

    public init() { }

    private var provider: TMTunnelProviderManager!

    public weak var delegate: TMExtensionManagerDelegate?

    public func setTunnelProvider(_ provider: TMTunnelProviderManager) {
        self.provider = provider
        provider.delegate = self
    }

    public func start() {
        provider.startTunnel()
    }

    public func stop() {
        provider.stopTunnel()
    }

    var session: TMTunnelProviderSession? {
        provider.session
    }

    public func startMonitoring<ServiceInfoRequest: Codable, ServiceInfoResponse: Codable>(
        withRequestBuilder requestBuilder: @escaping () -> ServiceInfoRequest,
        responseType: ServiceInfoResponse.Type,
        pollInterval: TimeInterval = 1.0
    ) {
        guard let session = session, session.status == .connected else {
            log(.error, "Unable to monitor session - incorrect state")
            return
        }
        provider.tunnelMonitor.startMonitoring(
            session: session,
            withRequestBuilder: requestBuilder,
            responseHandler: { (result: Result<ServiceInfo, TMCommunicationError>) in
                switch result {
                case .success(let response):
                    log(.info, "Response received: \(response)")
                    self.delegate?.serviceStateChanged(manager: self, to: response)
                case .failure(let error):
                    log(.error, "Error communicating with extension: \(error)")
                }
            },
            pollInterval: pollInterval
        )
    }

}

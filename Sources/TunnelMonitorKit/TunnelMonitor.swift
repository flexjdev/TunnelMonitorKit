//
//  TunnelMonitor.swift
//  TunnelMonitorKit
// 
//  Created by Chris J on 20/03/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation
import NetworkExtension

/// Responsible for communication with the NEPacketTunnel
/// Communication is bi-directional, but can only be initiated from the app layer
open class TunnelMonitor {

    func startMonitoring(session: NETunnelProviderSession) {

    }

//    open override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
//        guard let message = MessageContainer.decode(from: messageData) else {
//            return
//        }
//        _ = message
//    }
    
}

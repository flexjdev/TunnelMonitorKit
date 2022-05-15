//
//  NEIPv4Route+Util.swift
//  TunnelMonitorKit
//
//  Created by Chris J on 13/05/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation
import NetworkExtension

// swiftlint:disable force_try

/// Matches 0-255.0-255.0-255.0-255, e.g. 192.168.0.1 or 10.128.1.255 or 8.8.8.8
private let ipPattern = "((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)(\\.)){3}(25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)"
/// Matches a basic IPv4Route, such as 192.168.0.0:255.255.255.0. It uses capture groups for the address:subnet
private let routeRegex = try! NSRegularExpression(pattern: "^(?<address>\(ipPattern)):(?<subnet>\(ipPattern))$")

extension NEIPv4Route {

    /// Required to prevent invalid IP routes from being constructed, e.g. 0.0.0.0:0
    public convenience init?(from string: String) {
        let range = NSRange(location: 0, length: string.count)

        guard
            let match = routeRegex.firstMatch(in: string, options: [], range: range),
            let address = match.getMatchedGroup(named: "address", in: string),
            let subnet = match.getMatchedGroup(named: "address", in: string)
        else {
            log(.warning, "String \(string) is not a valid ip route of form a.b.c.d:w.x.y.z")
            return nil
        }

        self.init(destinationAddress: address, subnetMask: subnet)
    }
}

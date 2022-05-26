//
//  File.swift
//  TunnelMonitorKit
// 
//  Created by Chris J on 26/05/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import XCTest
import NetworkExtension
@testable import TunnelMonitorKit

final class NEIPv4RouteTests: XCTestCase {

    func testParseValidRoute() {
        let route = NEIPv4Route(from: "0.0.0.0:255.255.255.255")

        XCTAssertNotNil(route, "Valid route not parsed correctly")
        XCTAssertEqual(route?.destinationAddress, "0.0.0.0")
        XCTAssertEqual(route?.destinationSubnetMask, "255.255.255.255")
    }

    func testInvalidOctetValue() {
        let route1 = NEIPv4Route(from: "256.0.0.0:0.0.0.0")
        let route2 = NEIPv4Route(from: "0.0.0.0:-1.0.0.0")
        XCTAssertNil(route1)
        XCTAssertNil(route2)
    }

    func testInvalid() {
        let route = NEIPv4Route(from: "a.b.c.d:0.0.0.0")
        XCTAssertNil(route)
    }

    func testIncorrectAddressOctetCount() {
        let route = NEIPv4Route(from: "1.2.3:0.0.0.0")
        XCTAssertNil(route)
    }

    func testIncorrectSubnetOctetCount() {
        let route = NEIPv4Route(from: "1.2.3.4:0.0.0")
        XCTAssertNil(route)
    }

    func testIncorrectSeparator() {
        let route = NEIPv4Route(from: "1.2.3.4.0.0.0.0")
        XCTAssertNil(route)
    }

}

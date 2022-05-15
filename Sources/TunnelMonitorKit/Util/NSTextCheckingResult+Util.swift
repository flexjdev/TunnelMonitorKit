//
//  NSTextCheckingResult+Util.swift
//  TunnelMonitorKit
//
//  Created by Chris J on 13/05/2022.
//  Copyright © 2022 Chris Janusiewicz. Distributed under the MIT License.
//

import Foundation

extension NSTextCheckingResult {
    /// Helper function for retrieving regex match for named capture groups
    public func getMatchedGroup(named name: String, in string: String) -> String? {
        if let range = Range(self.range(withName: name), in: string) {
            return String(string[range])
        }
        return nil
    }
}

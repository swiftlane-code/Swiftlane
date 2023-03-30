//

import Foundation

// swiftformat:disable all

public extension PeripheryModels {
	/// From periphery 2.9.0 release.
	/// See https://github.com/peripheryapp/periphery/blob/master/Sources/PeripheryKit/Indexer/Accessibility.swift
	enum Accessibility: String, Codable {
		case `public` = "public"
		case `internal` = "internal"
		case `private` = "private"
		case `fileprivate` = "fileprivate"
		case `open` = "open"
		case unknown = ""
	}
}

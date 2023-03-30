//

import Foundation

// swiftformat:disable all

public extension PeripheryModels {
	/// From periphery 2.9.0 release.
	/// See https://github.com/peripheryapp/periphery/blob/master/Sources/PeripheryKit/ScanResult.swift
	enum Annotation: String, Codable {
		case unused
		case assignOnlyProperty
		case redundantProtocol
		case redundantPublicAccessibility
		/// See https://github.com/peripheryapp/periphery/blob/master/Sources/Frontend/Formatters/OutputFormatter.swift
		case redundantConformance
	}
}

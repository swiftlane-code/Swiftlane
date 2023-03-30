//

import Foundation
import SwiftlaneCore

// swiftformat:disable all

public extension PeripheryModels {
	/// From periphery 2.9.0 release.
	/// See https://github.com/peripheryapp/periphery/blob/master/Sources/Frontend/Formatters/JsonFormatter.swift
	struct ScanResult: Codable {
		public let kind: PeripheryModels.Kind
		public let name: String
		public let modifiers: Set<String>
		public let attributes: Set<String>
		public let accessibility: Accessibility
		public let hints: AnnotationContainer
		public let location: Location
		
		public struct AnnotationContainer: Codable {
			public let annotation: Annotation
			
			public init(from decoder: Decoder) throws {
				let container = try decoder.singleValueContainer()
				let array = try container.decode([Annotation].self)
				self.annotation = try array.first.unwrap(
					errorDescription: "hints array of a ScanResult is empty."
				)
			}
			
			public func encode(to encoder: Encoder) throws {
				var container = encoder.singleValueContainer()
				try container.encode([self.annotation])
			}
		}
		
		public struct Location: Codable {
			let fileLineColumn: String
			
			let file: AbsolutePath
			let line: UInt
			let column: UInt
			
			public init(from decoder: Decoder) throws {
				let container = try decoder.singleValueContainer()
				fileLineColumn = try container.decode(String.self)

				// swiftformat:disable:next indent
				let errorDescription = "location \(fileLineColumn.quoted) in json produced by periphery is malformed." +
					" Expected format: \"<file>:<line>:<column>\""
				
				func parseUInt(_ string: Substring?) throws -> UInt {
					try string.flatMap { UInt($0) }.unwrap(errorDescription: errorDescription)
				}
				
				let parts = fileLineColumn.split(separator: ":")
				
				file = try parts[safe: 0].map(AbsolutePath.init).unwrap(errorDescription: errorDescription)
				line = try parseUInt(parts[safe: 1])
				column = try parseUInt(parts[safe: 2])
			}
			
			public func encode(to encoder: Encoder) throws {
				var container = encoder.singleValueContainer()
				try container.encode(fileLineColumn)
			}
		}
	}
}

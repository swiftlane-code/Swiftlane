//

import Foundation

// swiftformat:disable all

public extension PeripheryModels {
	/// From periphery 2.9.0 release.
	/// See https://github.com/peripheryapp/periphery/blob/master/Sources/PeripheryKit/Indexer/Declaration.swift
	enum Kind: String, RawRepresentable, CaseIterable, Codable {
		case `associatedtype` = "associatedtype"
		case `class` = "class"
		case `enum` = "enum"
		case enumelement = "enumelement"
		case `extension` = "extension"
		case extensionClass = "extension.class"
		case extensionEnum = "extension.enum"
		case extensionProtocol = "extension.protocol"
		case extensionStruct = "extension.struct"
		case functionAccessorAddress = "function.accessor.address"
		case functionAccessorDidset = "function.accessor.didset"
		case functionAccessorGetter = "function.accessor.getter"
		case functionAccessorMutableaddress = "function.accessor.mutableaddress"
		case functionAccessorSetter = "function.accessor.setter"
		case functionAccessorWillset = "function.accessor.willset"
		case functionConstructor = "function.constructor"
		case functionDestructor = "function.destructor"
		case functionFree = "function.free"
		case functionMethodClass = "function.method.class"
		case functionMethodInstance = "function.method.instance"
		case functionMethodStatic = "function.method.static"
		case functionOperator = "function.operator"
		case functionOperatorInfix = "function.operator.infix"
		case functionOperatorPostfix = "function.operator.postfix"
		case functionOperatorPrefix = "function.operator.prefix"
		case functionSubscript = "function.subscript"
		case genericTypeParam = "generic_type_param"
		case module = "module"
		case precedenceGroup = "precedencegroup"
		case `protocol` = "protocol"
		case `struct` = "struct"
		case `typealias` = "typealias"
		case varClass = "var.class"
		case varGlobal = "var.global"
		case varInstance = "var.instance"
		case varLocal = "var.local"
		case varParameter = "var.parameter"
		case varStatic = "var.static"
		
		public static var functionKinds: Set<Kind> {
			Set(Kind.allCases.filter { $0.isFunctionKind })
		}
		
		public var isFunctionKind: Bool {
			rawValue.hasPrefix("function")
		}
		
		public static var variableKinds: Set<Kind> {
			Set(Kind.allCases.filter { $0.isVariableKind })
		}
		
		public var isVariableKind: Bool {
			rawValue.hasPrefix("var")
		}
		
		public static var globalKinds: Set<Kind> = [
			.class,
			.protocol,
			.enum,
			.struct,
			.typealias,
			.functionFree,
			.extensionClass,
			.extensionStruct,
			.extensionProtocol,
			.varGlobal
		]
		
		public static var extensionKinds: Set<Kind> {
			Set(Kind.allCases.filter { $0.isExtensionKind })
		}
		
		public var extendedKind: Kind? {
			switch self {
			case .extensionClass:
				return .class
			case .extensionStruct:
				return .struct
			case .extensionEnum:
				return .enum
			case .extensionProtocol:
				return .protocol
			default:
				return nil
			}
		}
		
		public var isExtensionKind: Bool {
			rawValue.hasPrefix("extension")
		}
		
		public var isConformableKind: Bool {
			isDiscreteConformableKind || isExtensionKind
		}
		
		public var isDiscreteConformableKind: Bool {
			Self.discreteConformableKinds.contains(self)
		}
		
		public static var discreteConformableKinds: Set<Kind> {
			return [.class, .struct, .enum]
		}
		
		public static var accessorKinds: Set<Kind> {
			Set(Kind.allCases.filter { $0.isAccessorKind })
		}
		
		public static var accessibleKinds: Set<Kind> {
			functionKinds.union(variableKinds).union(globalKinds)
		}
		
		public var isAccessorKind: Bool {
			rawValue.hasPrefix("function.accessor")
		}
		
		public static var toplevelAttributableKind: Set<Kind> {
			[.class, .struct, .enum]
		}
		
		public var displayName: String? {
			switch self {
			case .class:
				return "class"
			case .protocol:
				return "protocol"
			case .struct:
				return "struct"
			case .enum:
				return "enum"
			case .enumelement:
				return "public enum case"
			case .typealias:
				return "typealias"
			case .associatedtype:
				return "associatedtype"
			case .functionConstructor:
				return "initializer"
			case .extension, .extensionEnum, .extensionClass, .extensionStruct, .extensionProtocol:
				return "extension"
			case .functionMethodClass, .functionMethodStatic, .functionMethodInstance, .functionFree, .functionOperator, .functionSubscript:
				return "function"
			case .varStatic, .varInstance, .varClass, .varGlobal, .varLocal:
				return "property"
			case .varParameter:
				return "parameter"
			case .genericTypeParam:
				return "generic type parameter"
			default:
				return nil
			}
		}
	}
}

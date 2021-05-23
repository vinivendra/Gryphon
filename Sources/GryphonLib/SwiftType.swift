//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license.md
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// TODO:
// - Add a String to SwiftType, created from its description
// - Use the string everywhere
// - Make the string be updated when the type changes
// - Remove the string little by little, top to bottom

/**
* `SwiftType`s are organized as in a pseudo-subclass hierarchy, but using structs. The superclass is
* `SwiftType`, and the subclasses are the nested types of `SwiftType` which conform to
* `SwiftTypeRefined`, e.g. `Optional`, `Function`, etc. `SwiftType`s contain a `SwiftTypeContents`
* enum inside them that determines which "subclass" they are and which contain the struct that
* corresponds to that subclass.
*/
struct SwiftType: Equatable {
	var contents: SwiftTypeContents
	var attributes: MutableList<String>

	init(_ contents: SwiftTypeContents, attributes: MutableList<String> = []) {
		self.contents = contents
		self.attributes = attributes
	}
}

indirect enum SwiftTypeContents: Equatable {
	case named(SwiftType.Named)
	case optional(SwiftType.Optional)
	case dot(SwiftType.Dot)
	case tuple(SwiftType.Tuple)
	case function(SwiftType.Function)
	case generic(SwiftType.Generic)
}

extension SwiftType: CustomStringConvertible {
	var description: String {
		if attributes.isEmpty {
			return contents.description
		}
		else {
			return attributes.joined(separator: " ") + " " + contents.description
		}
	}
}

extension SwiftTypeContents: CustomStringConvertible {
	var refinedType: SwiftTypeRefined {
		switch self {
		case let .named(refinedType):
			return refinedType
		case let .optional(refinedType):
			return refinedType
		case let .dot(refinedType):
			return refinedType
		case let .tuple(refinedType):
			return refinedType
		case let .function(refinedType):
			return refinedType
		case let .generic(refinedType):
			return refinedType
		}
	}

	var description: String {
		switch self {
		case let .named(refinedType):
			return refinedType.description
		case let .optional(refinedType):
			return refinedType.description
		case let .dot(refinedType):
			return refinedType.description
		case let .tuple(refinedType):
			return refinedType.description
		case let .function(refinedType):
			return refinedType.description
		case let .generic(refinedType):
			return refinedType.description
		}
	}
}

extension SwiftType {
	static func named(
		typeName: String,
		attributes: MutableList<String> = [])
		-> SwiftType
	{
		return SwiftType(
			.named(SwiftType.Named(typeName: typeName)),
			attributes: attributes)
	}

	static func optional(
		subType: SwiftType,
		attributes: MutableList<String> = [])
		-> SwiftType
	{
		return SwiftType(
			.optional(SwiftType.Optional(subType: subType)),
			attributes: attributes)
	}

	static func dot(
		leftType: SwiftType, rightType: String,
		attributes: MutableList<String> = [])
		-> SwiftType
	{
		return SwiftType(
			.dot(SwiftType.Dot(leftType: leftType, rightType: rightType)),
			attributes: attributes)
	}

	static func tuple(
		subTypes: MutableList<LabeledSwiftType>,
		attributes: MutableList<String> = [])
		-> SwiftType
	{
		return SwiftType(
			.tuple(SwiftType.Tuple(subTypes: subTypes)),
			attributes: attributes)
	}

	static func function(
		parameters: MutableList<SwiftType>, returnType: SwiftType,
		attributes: MutableList<String> = [])
		-> SwiftType
	{
		return SwiftType(
			.function(SwiftType.Function(parameters: parameters, returnType: returnType)),
			attributes: attributes)
	}

	static func generic(
		typeName: String, genericArguments: MutableList<SwiftType>,
		attributes: MutableList<String> = [])
		-> SwiftType
	{
		return SwiftType(
			.generic(SwiftType.Generic(typeName: typeName, genericArguments: genericArguments)),
			attributes: attributes)
	}

	/// Creates an Array type with the given element type.
	static func array(
		of element: SwiftType,
		attributes: MutableList<String> = [])
		-> SwiftType
	{
		return .generic(
			typeName: "Array", genericArguments: [element],
			attributes: attributes)
	}

	/// Creates a Dictionary type with the given key and value types.
	static func dictionary(
		withKey key: SwiftType, value: SwiftType,
		attributes: MutableList<String> = [])
		-> SwiftType
	{
		return .generic(
			typeName: "Dictionary", genericArguments: [key, value],
			attributes: attributes)
	}
}

extension SwiftType {
	var isNamed: Bool {
		switch contents {
		case .named(_):
			return true
		default:
			return false
		}
	}

	var isOptional: Bool {
		switch contents {
		case .optional(_):
			return true
		default:
			return false
		}
	}

	var isDot: Bool {
		switch contents {
		case .dot(_):
			return true
		default:
			return false
		}
	}

	var isTuple: Bool {
		switch contents {
		case .tuple(_):
			return true
		default:
			return false
		}
	}

	var isFunction: Bool {
		switch contents {
		case .function(_):
			return true
		default:
			return false
		}
	}

	var isGeneric: Bool {
		switch contents {
		case .generic(_):
			return true
		default:
			return false
		}
	}
}

extension SwiftType {
	var asNamed: Named? {
		switch self.contents {
		case let .named(refinedType):
			return refinedType
		default:
			return nil
		}
	}

	var asOptional: Optional? {
		switch self.contents {
		case let .optional(refinedType):
			return refinedType
		default:
			return nil
		}
	}

	var asDot: Dot? {
		switch self.contents {
		case let .dot(refinedType):
			return refinedType
		default:
			return nil
		}
	}

	var asTuple: Tuple? {
		switch self.contents {
		case let .tuple(refinedType):
			return refinedType
		default:
			return nil
		}
	}

	var asFunction: Function? {
		switch self.contents {
		case let .function(refinedType):
			return refinedType
		default:
			return nil
		}
	}

	var asGeneric: Generic? {
		switch self.contents {
		case let .generic(refinedType):
			return refinedType
		default:
			return nil
		}
	}
}

protocol SwiftTypeRefined: CustomStringConvertible { }

extension SwiftType {
	struct Named: SwiftTypeRefined, Equatable {
		let typeName: String

		var description: String {
			return typeName
		}

		var asSwiftType: SwiftType {
			return SwiftType(.named(self))
		}
	}

	struct Optional: SwiftTypeRefined, Equatable {
		let subType: SwiftType

		var description: String {
			if subType.isFunction {
				return "(\(subType))?"
			}
			else {
				return "\(subType)?"
			}
		}

		var asSwiftType: SwiftType {
			return SwiftType(.optional(self))
		}
	}

	struct Dot: SwiftTypeRefined, Equatable {
		let leftType: SwiftType
		let rightType: String

		var description: String {
			return "\(leftType).\(rightType)"
		}

		var asSwiftType: SwiftType {
			return SwiftType(.dot(self))
		}
	}

	struct Tuple: SwiftTypeRefined, Equatable {
		let subTypes: MutableList<LabeledSwiftType>

		var description: String {
			let innerTypes = subTypes.map { $0.description }.joined(separator: ", ")
			return "(\(innerTypes))"
		}

		var asSwiftType: SwiftType {
			return SwiftType(.tuple(self))
		}
	}

	struct Function: SwiftTypeRefined, Equatable {
		let parameters: MutableList<SwiftType>
		let returnType: SwiftType

		var description: String {
			let parameterStrings = parameters.map { $0.description }.joined(separator: ", ")
			return "(\(parameterStrings)) -> \(returnType)"
		}

		var asSwiftType: SwiftType {
			return SwiftType(.function(self))
		}
	}
	
	struct Generic: SwiftTypeRefined, Equatable {
		let typeName: String
		let genericArguments: MutableList<SwiftType>

		var description: String {
			let genericStrings = genericArguments.map { $0.description }.joined(separator: ", ")
			return "\(typeName)<\(genericStrings)>"
		}

		var asSwiftType: SwiftType {
			return SwiftType(.generic(self))
		}
	}
}

struct LabeledSwiftType: CustomStringConvertible, Equatable {
	let label: String?
	let swiftType: SwiftType

	init(label: String?, swiftType: SwiftType) {
		self.label = (label == "_") ? nil : label
		self.swiftType = swiftType
	}

	var description: String {
		if let label = label {
			return "\(label): \(swiftType)"
		}
		else {
			return swiftType.description
		}
	}
}

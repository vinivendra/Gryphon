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
// - Use SwiftType's parser to get the types from SourceKit
//     (and convert them back to string for the rest of the translation)

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

//	static func create(fromString string: String) -> SwiftType? {
//		return Parser(string: string).parse()
//	}
//
//	private class Parser {
//		let string: String
//		var index: String.Index
//
//		init(string: String) {
//			self.string = string
//			self.index = string.startIndex
//		}
//
//		func parse() -> SwiftType? {
//			guard !string.isEmpty else {
//				return nil
//			}
//
//			let result = parseType()
//			cleanLeadingWhitespace()
//
//			// If there's still something left to parse, then something went wrong.
//			guard index == string.endIndex else {
//				return nil
//			}
//
//			return result
//		}
//
//		func cleanLeadingWhitespace() {
//			while index != string.endIndex, string[index] == " " {
//				index = string.index(after: index)
//			}
//		}
//
//		/// Parses the next type, starting at `index`. Leaves `index` in the position after the end
//		/// of the parsed type if successful; returns `nil` otherwise.
//		private func parseType() -> SwiftType? {
//			guard let nonOptionalType = parseNonOptionalType() else {
//				return nil
//			}
//
//			var result = nonOptionalType
//
//			/// Checks for "?"s after the type
//			while index != string.endIndex, string[index] == "?" {
//				index = string.index(after: index)
//				result = .optional(subType: result)
//			}
//
//			return result
//		}
//
//		/// Parses a type ignoring possible "?"s at its end
//		private func parseNonOptionalType() -> SwiftType? {
//			cleanLeadingWhitespace()
//
//			// TODO:
//			// - autoclosure
//			// - convention
//			// - escaping
//			// - throws
//			// - rethrows
//
//			if string.contains("autoclosure") ||
//				string.contains("convention") ||
//				string.contains("escaping") ||
//				string.contains("throws")
//			{
//				print("Error parsing:")
//				print(string)
//				fatalError(string)
//			}
//
//			// Two special cases: types with `inout` and `__owned` prefixes
//			if string[index...].hasPrefix("inout ") {
//				index = string.index(index, offsetBy: "inout ".count)
//				return parseNonOptionalType()
//			}
//
//			if string[index...].hasPrefix("__owned ") {
//				index = string.index(index, offsetBy: "__owned ".count)
//				return parseNonOptionalType()
//			}
//
//			// Arrays, dictionarys and tuples/functions can start with brackets and parentheses, so
//			// we can detect them earlier. Generics and optionals can only be detected later since
//			// the "<...>" and "?" are postfix.
//
//			// If it's an array or a dictionary
//			if string[index] == "[" {
//				index = string.index(after: index)
//
//				guard let subType1 = parseType() else {
//					return nil
//				}
//
//				// If it's an array
//				if string[index] != ":" {
//					guard string[index] == "]" else {
//						return nil
//					}
//
//					index = string.index(after: index)
//					return .array(of: subType1)
//				}
//				else {
//					// if it's a dictionary
//
//					index = string.index(after: index)
//
//					guard let subType2 = parseType() else {
//						return nil
//					}
//
//					guard string[index] == "]" else {
//						return nil
//					}
//
//					index = string.index(after: index)
//					return .generic(typeName: "Dictionary", genericArguments: [subType1, subType2])
//				}
//			}
//
//			// If it's a tuple
//			if string[index] == "(" {
//				index = string.index(after: index)
//
//				// Check for labels before the tuple type, i.e. `(bla: Int, foo: String)` should be
//				// parsed as `(Int, String)`
//
//				let subType1: SwiftType
//				guard let firstAttempt = parseType() else {
//					return nil
//				}
//				// If we read a label instead of a type, try again
//				if string[index] == ":" {
//					index = string.index(after: index)
//					cleanLeadingWhitespace()
//					guard let secondAttempt = parseType() else {
//						return nil
//					}
//					subType1 = secondAttempt
//				}
//				else {
//					subType1 = firstAttempt
//				}
//
//				let tupleElements: MutableList = [subType1]
//
//				while string[index] == "," {
//					index = string.index(after: index)
//
//					// Check for labels just as before
//					let newSubType: SwiftType
//					guard let firstAttempt = parseType() else {
//						return nil
//					}
//					if string[index] == ":" {
//						index = string.index(after: index)
//						cleanLeadingWhitespace()
//						guard let secondAttempt = parseType() else {
//							return nil
//						}
//						newSubType = secondAttempt
//					}
//					else {
//						newSubType = firstAttempt
//					}
//
//					tupleElements.append(newSubType)
//				}
//
//				guard string[index] == ")" else {
//					return nil
//				}
//				index = string.index(after: index)
//				cleanLeadingWhitespace()
//
//				// Check if it's a standard tuple or if it's part of a function type
//
//				if string[index...].hasPrefix("->") {
//					// If it's a function type, skip the "->" and any possible whitespace after it
//					index = string.index(index, offsetBy: 2)
//					cleanLeadingWhitespace()
//
//					guard let returnType = parseType() else {
//						return nil
//					}
//
//					return .function(parameters: tupleElements, returnType: returnType)
//				}
//				else {
//					// If it's not a function it can still be a simple wrapping parameter
//					// i.e. ((String) -> String)?
//					if tupleElements.count == 1 {
//						return tupleElements[0]
//					}
//					else {
//						return .tuple(subTypes: tupleElements.map {
//							LabeledSwiftType(label: nil, swiftType: $0)
//						}.toMutableList())
//					}
//				}
//			}
//
//			// If it doesn't start with a special character, try to read it as a normal type
//			var normalTypeEndIndex = index
//			while normalTypeEndIndex != string.endIndex,
//				(string[normalTypeEndIndex].isLetter ||
//					string[normalTypeEndIndex].isNumber ||
//					string[normalTypeEndIndex] == "_")
//			{
//				normalTypeEndIndex = string.index(after: normalTypeEndIndex)
//			}
//
//			// If it's empty, something went wrong
//			guard normalTypeEndIndex != index else {
//				return nil
//			}
//
//			let normalType = String(string[index..<normalTypeEndIndex])
//			index = normalTypeEndIndex
//			cleanLeadingWhitespace()
//
//			// Check if it's a generic
//			if index != string.endIndex, string[index] == "<" {
//				index = string.index(after: index)
//
//				guard let subType1 = parseType() else {
//					return nil
//				}
//
//				let genericElements: MutableList = [subType1]
//
//				while string[index] == "," {
//					index = string.index(after: index)
//
//					guard let newSubType = parseType() else {
//						return nil
//					}
//
//					genericElements.append(newSubType)
//				}
//
//				guard string[index] == ">" else {
//					return nil
//				}
//				index = string.index(after: index)
//
//				// If it's an optional written as a generic
//				if normalType == "Optional", genericElements.count == 1 {
//					return .optional(subType: genericElements[0])
//				}
//
//				// Otherwise, it's just a normal generic type
//				return .generic(typeName: normalType, genericArguments: genericElements)
//			}
//
//			// Otherwise, consider it a normal type
//			return .namedType(typeName: normalType)
//		}
//	}
//
//	func isSubtype(of superType: SwiftType) -> Bool {
//		// Trivial case
//		if self == superType {
//			return true
//		}
//
//		// Special cases that are considered superTypes of anything (for simplicity in the standard
//		// library translations)
//		if case let .namedType(typeName: namedSuperType) = superType {
//			if namedSuperType == "Any" ||
//				namedSuperType == "_Any" ||
//				namedSuperType == "_Hashable" ||
//				namedSuperType == "_Comparable" ||
//				namedSuperType == "_Optional"
//			{
//				return true
//			}
//		}
//		if case let .optional(subType: optionalSuperType) = superType {
//			if case let .namedType(typeName: namedSuperType) = optionalSuperType {
//				if namedSuperType == "_Optional" {
//					if case .optional = self {
//						return true
//					}
//					else {
//						return false
//					}
//				}
//			}
//		}
//
//		// Tuples are subtypes if their components are subtypes
//		if case let .tuple(subTypes: selfSubTypes) = self,
//			case let .tuple(subTypes: superSubTypes) = superType
//		{
//			guard selfSubTypes.count == superSubTypes.count else {
//				return false
//			}
//
//			for (selfSubType, superSubType) in zip(selfSubTypes, selfSubTypes) {
//				guard selfSubType.swiftType.isSubtype(of: superSubType.swiftType) else {
//					return false
//				}
//			}
//		}
//
//		// Try to simplify the types, if possible
//		if let simpleSelf = simplifyType(self) {
//			return simpleSelf.isSubtype(of: superType)
//		}
//		else if let simpleSuperType = simplifyType(superType) {
//			return self.isSubtype(of: simpleSuperType)
//		}
//
//		// Handle optionals:
//		// X? < Y? <=> X < Y
//		// X < Y? <=> X < Y
//		if case let .optional(subType: optionalSuperType) = superType {
//			if case let .optional(subType: optionalSelf) = self {
//				return optionalSelf.isSubtype(of: optionalSuperType)
//			}
//			else {
//				return self.isSubtype(of: optionalSuperType)
//			}
//		}
//
//		// Handle functions:
//		// Functions are always considered a subType of one another. They have edge cases that are
//		// difficult to handle correctly, and it's rare for them to appear so false positives should
//		// also be rare.
//		if case .function = superType {
//			if case .function = self {
//				return true
//			}
//			else {
//				return false
//			}
//		}
//
//		// Handle arrays
//		if let superElementType = superType.arrayElement {
//			if let selfElementType = self.arrayElement {
//				return selfElementType.isSubtype(of: superElementType)
//			}
//			else {
//				return false
//			}
//		}
//
//		// Handle dictionaries
//		if let (superKey, superValue) = superType.dictionaryKeyAndValue {
//			if let (selfKey, selfValue) = self.dictionaryKeyAndValue {
//				return selfKey.isSubtype(of: superKey) && selfValue.isSubtype(of: superValue)
//			}
//			else {
//				return false
//			}
//		}
//
//		// Handle generics
//		if case let .generic(
//			typeName: superTypeName,
//			genericArguments: superTypeArguments) = superType
//		{
//			if case let .generic(
//				typeName: selfTypeName,
//				genericArguments: selfTypeArguments) = self
//			{
//				// Check if the named parts are the same
//				let namedSuperType = SwiftType.namedType(typeName: superTypeName)
//				let namedSelfType = SwiftType.namedType(typeName: selfTypeName)
//				guard namedSelfType.isSubtype(of: namedSuperType) else {
//					return false
//				}
//
//				// Check if the arguments are the same
//				guard superTypeArguments.count == selfTypeArguments.count else {
//					return false
//				}
//
//				for (selfTypeArgument, superTypeArgument) in
//					zip(selfTypeArguments, superTypeArguments)
//				{
//					guard selfTypeArgument.isSubtype(of: superTypeArgument) else {
//						return false
//					}
//				}
//			}
//			else {
//				return false
//			}
//		}
//
//		return false
//	}
//
//	private func simplifyType(_ gryphonType: SwiftType) -> SwiftType? {
//		// Deal with standard library types that can be handled as other types
//		if case let .namedType(typeName: typeName) = gryphonType {
//			if let result = Utilities.getTypeMapping(for: typeName) {
//				return .namedType(typeName: result)
//			}
//		}
//
//		if case let .generic(typeName: typeName, genericArguments: genericArguments) = gryphonType {
//			if gryphonType.arrayElement != nil {
//				return gryphonType
//			}
//
//			// Treat Slice as Array
//			if typeName == "Slice",
//				genericArguments.count == 1,
//				case let .generic(
//					typeName: innerTypeName,
//					genericArguments: innerGenericArguments) = genericArguments[0]
//			{
//				if innerTypeName == "MutableList" || innerTypeName == "List" {
//					return .generic(
//						typeName: innerTypeName,
//						genericArguments: [innerGenericArguments[0]])
//				}
//			}
//
//			// Treat MutableMap as Dictionary
//			if typeName == "MutableMap" || typeName == "Map" {
//				// MutableMap should have exactly two generic argument: a key and a value
//				return .dictionary(withKey: genericArguments[0], value: genericArguments[1])
//			}
//		}
//
//		return nil
//	}

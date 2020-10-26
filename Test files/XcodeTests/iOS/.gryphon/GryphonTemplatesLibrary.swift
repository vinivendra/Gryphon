// WARNING: Any changes to this file should be reflected in the literal string in
// AuxiliaryFileContents.swift

import Foundation

// MARK: - Define template classes and operators

// gryphon ignore
private class _GRYTemplate {
	static func dot(_ left: _GRYTemplate, _ right: String) -> _GRYDotTemplate {
		return _GRYDotTemplate(left, right)
	}

	static func dot(_ left: String, _ right: String) -> _GRYDotTemplate {
		return _GRYDotTemplate(_GRYLiteralTemplate(string: left), right)
	}

	static func call(_ function: _GRYTemplate, _ parameters: [_GRYParameterTemplate]) -> _GRYCallTemplate {
		return _GRYCallTemplate(function, parameters)
	}

	static func call(_ function: String, _ parameters: [_GRYParameterTemplate]) -> _GRYCallTemplate {
		return _GRYCallTemplate(function, parameters)
	}
}

// gryphon ignore
private class _GRYDotTemplate: _GRYTemplate {
	let left: _GRYTemplate
	let right: String

	init(_ left: _GRYTemplate, _ right: String) {
		self.left = left
		self.right = right
	}
}

// gryphon ignore
private class _GRYCallTemplate: _GRYTemplate {
	let function: _GRYTemplate
	let parameters: [_GRYParameterTemplate]

	init(_ function: _GRYTemplate, _ parameters: [_GRYParameterTemplate]) {
		self.function = function
		self.parameters = parameters
	}

	//
	init(_ function: String, _ parameters: [_GRYParameterTemplate]) {
		self.function = _GRYLiteralTemplate(string: function)
		self.parameters = parameters
	}
}

// gryphon ignore
private class _GRYParameterTemplate: ExpressibleByStringLiteral {
	let label: String?
	let template: _GRYTemplate

	private init(_ label: String?, _ template: _GRYTemplate) {
		if let existingLabel = label {
			if existingLabel == "_" || existingLabel == "" {
				self.label = nil
			}
			else {
				self.label = label
			}
		}
		else {
			self.label = label
		}

		self.template = template
	}

	required init(stringLiteral: String) {
		self.label = nil
		self.template = _GRYLiteralTemplate(string: stringLiteral)
	}

	static func labeledParameter(_ label: String?, _ template: _GRYTemplate) -> _GRYParameterTemplate {
		return _GRYParameterTemplate(label, template)
	}

	static func labeledParameter(_ label: String?, _ template: String) -> _GRYParameterTemplate {
		return _GRYParameterTemplate(label, _GRYLiteralTemplate(string: template))
	}

	static func dot(_ left: _GRYTemplate, _ right: String) -> _GRYParameterTemplate {
		return _GRYParameterTemplate(nil, _GRYDotTemplate(left, right))
	}

	static func dot(_ left: String, _ right: String) -> _GRYParameterTemplate {
		return _GRYParameterTemplate(nil, _GRYDotTemplate(_GRYLiteralTemplate(string: left), right))
	}

	static func call(_ function: _GRYTemplate, _ parameters: [_GRYParameterTemplate]) -> _GRYParameterTemplate {
		return _GRYParameterTemplate(nil, _GRYCallTemplate(function, parameters))
	}

	static func call(_ function: String, _ parameters: [_GRYParameterTemplate]) -> _GRYParameterTemplate {
		return _GRYParameterTemplate(nil, _GRYCallTemplate(function, parameters))
	}
}

// gryphon ignore
private class _GRYLiteralTemplate: _GRYTemplate {
	let string: String

	init(string: String) {
		self.string = string
	}
}

// gryphon ignore
private class _GRYConcatenatedTemplate: _GRYTemplate {
	let left: _GRYTemplate
	let right: _GRYTemplate

	init(left: _GRYTemplate, right: _GRYTemplate) {
		self.left = left
		self.right = right
	}
}

// gryphon ignore
private func + (left: _GRYTemplate, right: _GRYTemplate) -> _GRYConcatenatedTemplate {
	_GRYConcatenatedTemplate(left: left, right: right)
}

// gryphon ignore
private func + (left: String, right: _GRYTemplate) -> _GRYConcatenatedTemplate {
	_GRYConcatenatedTemplate(left: _GRYLiteralTemplate(string: left), right: right)
}

// gryphon ignore
private func + (left: _GRYTemplate, right: String) -> _GRYConcatenatedTemplate {
	_GRYConcatenatedTemplate(left: left, right: _GRYLiteralTemplate(string: right))
}

// MARK: - Define special types as stand-ins for some protocols and other types

// Replacement for Hashable
private struct _Hashable: Hashable { }

// Replacement for Comparable
private struct _Comparable: Comparable {
	static func < (lhs: _Comparable, rhs: _Comparable) -> Bool {
		return false
	}
}

// Replacement for Optional
private struct _Optional { }

// Replacement for CustomStringConvertible
private struct _CustomStringConvertible: CustomStringConvertible {
	var description: String = ""
}

// Replacement for Any
private struct _Any: CustomStringConvertible, LosslessStringConvertible {
	init() { }

	var description: String = ""

	init?(_ description: String) {
		return nil
	}
}

// MARK: - Define the templates
private func gryphonTemplates() {

	// MARK: Declare placeholder variables to use in the templates
	var _bool: Bool = true
	var _strArray: [String] = []
	var _array: [Any] = []
	var _array1: [Any] = []
	var _array2: [Any] = []
	let _array3: [Any] = []
	var _arrayOfOptionals: [Any?] = []
	var _comparableArray: [_Comparable] = []
	let _comparable = _Comparable()
	var _index: String.Index = "abc".endIndex
	let _index1: String.Index = "abc".startIndex
	let _index2: String.Index = "abc".startIndex
	var _string: String = "abc"
	var _string1: String = "abc"
	let _string2: String = "abc"
	let _string3: String = "abc"
	let _character: Character = "a"
	let _substring: Substring = "abc".dropLast()
	let _range: Range<String.Index> = _string.startIndex..<_string.endIndex
	let _any: Any = "abc"
	let _anyType: _Any = _Any()
	let _customStringConvertible = _CustomStringConvertible()
	let _optional: _Optional? = _Optional()
	let _float: Float = 0
	let _double: Double = 0
	let _double1: Double = 0
	let _double2: Double = 0
	let _int: Int = 0
	let _int1: Int = 0
	let _int2: Int = 0
	let _dictionary: [_Hashable: Any] = [:]
	let _closure: (Any, Any) -> Any = { a, b in a }
	let _closure2: (Any) -> Any = { a in a }
	let _closure3: (Any) -> Bool = { _ in true }
	let _closure4: (_Optional) -> Any = { _ in true }
	let _closure5: (Character) -> Bool = { _ in true }
	let _closure6: (Any) -> Any? = { a in a }
	let _closure7: (_Comparable, _Comparable) -> Bool = { _, _ in true }

	// MARK: Declare the templates

	// System
	_ = print(_any) // gryphon pure
	_ = _GRYTemplate.call("println", ["_any"])

	_ = print(_any, terminator: "") // gryphon pure
	_ = _GRYTemplate.call("print", ["_any"])

	_ = fatalError(_string) // gryphon pure
	_ = _GRYTemplate.call("println",
			["\"Fatal error: ${_string}\""]) +
		"; " +
		_GRYTemplate.call("exitProcess", ["-1"])

	_ = assert(_bool) // gryphon pure
	_ = _GRYTemplate.call("assert", ["_bool"])

	// Darwin
	_ = sqrt(_double) // gryphon pure
	_ = _GRYTemplate.call(.dot("Math", "sqrt"), ["_double"])

	// Numerics
	_ = Double(_int)
	_ = "_int.toDouble()"

	_ = Float(_int)
	_ = "_int.toFloat()"

	_ = Double(_float)
	_ = "_float.toDouble()"

	_ = Int(_float)
	_ = "_float.toInt()"

	_ = Float(_double)
	_ = "_double.toFloat()"

	_ = Int(_double)
	_ = "_double.toInt()"

	// String
	_ = String(_anyType) // gryphon pure
	_ = _GRYTemplate.call(.dot("_anyType", "toString"), [])

	_ = _customStringConvertible.description // gryphon pure
	_ = _GRYTemplate.call(.dot("_customStringConvertible", "toString"), [])

	_ = _string.isEmpty // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "isEmpty"), [])

	_ = _string.count
	_ = _GRYTemplate.dot("_string", "length")

	_ = _string.first // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "firstOrNull"), [])

	_ = _string.last // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "lastOrNull"), [])

	_ = Double(_string) // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "toDouble"), [])

	_ = Float(_string) // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "toFloat"), [])

	_ = UInt64(_string) // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "toULong"), [])

	_ = Int64(_string) // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "toLong"), [])

	_ = Int(_string) // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "toIntOrNull"), [])

	_ = _string.dropLast() // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "dropLast"), ["1"])

	_ = _string.dropLast(_int) // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "dropLast"), ["_int"])

	_ = _string.dropFirst() // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "drop"), ["1"])

	_ = _string.dropFirst(_int) // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "drop"), ["_int"])

	_ = _string.drop(while: _closure5)
	_ = _GRYTemplate.call(.dot("_string", "dropWhile"), ["_closure5"])

	_ = _string.indices
	_ = _GRYTemplate.dot("_string", "indices")

	_ = _string.firstIndex(of: _character)! // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "indexOf"), ["_character"])

	_ = _string.contains(where: _closure5)
	_ = "(" + _GRYTemplate.call(.dot("_string", "find"), ["_closure5"]) + " != null)"

	_ = _string.firstIndex(of: _character) // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "indexOrNull"), ["_character"])

	_ = _string.prefix(_int) // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "substring"), ["0", "_int"])

	_ = _string.prefix(upTo: _index) // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "substring"), ["0", "_index"])

	_ = _string[_index...] // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "substring"), ["_index"])

	_ = _string[..<_index] // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "substring"), ["0", "_index"])

	_ = _string[..._index] // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "substring"), ["0", "_index + 1"])

	_ = _string[_index1..<_index2] // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "substring"), ["_index1", "_index2"])

	_ = _string[_index1..._index2] // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "substring"), ["_index1", "_index2 + 1"])

	_ = String(_substring)
	_ = "_substring"

	_ = _string.endIndex
	_ = _GRYTemplate.dot("_string", "length")

	_ = _string.startIndex
	_ = "0"

	_ = _string.formIndex(before: &_index)
	_ = "_index -= 1"

	_ = _string.index(after: _index)
	_ = "_index + 1"

	_ = _string.index(before: _index)
	_ = "_index - 1"

	_ = _string.index(_index, offsetBy: _int)
	_ = "_index + _int"

	_ = _substring.index(_index, offsetBy: _int)
	_ = "_index + _int"

	_ = _string1.replacingOccurrences(of: _string2, with: _string3)
	_ = _GRYTemplate.call(.dot("_string1", "replace"), ["_string2", "_string3"])

	_ = _string1.prefix(while: _closure5)
	_ = _GRYTemplate.call(.dot("_string1", "takeWhile"), ["_closure5"])

	_ = _string1.hasPrefix(_string2) // gryphon pure
	_ = _GRYTemplate.call(.dot("_string1", "startsWith"), ["_string2"])

	_ = _string1.hasSuffix(_string2) // gryphon pure
	_ = _GRYTemplate.call(.dot("_string1", "endsWith"), ["_string2"])

	_ = _range.lowerBound
	_ = _GRYTemplate.dot("_range", "start")

	_ = _range.upperBound
	_ = _GRYTemplate.dot("_range", "endInclusive")

	_ = Range<String.Index>(uncheckedBounds: (lower: _index1, upper: _index2))
	_ = _GRYTemplate.call("IntRange", ["_index1", "_index2"])

	_ = _string1.append(_string2)
	_ = "_string1 += _string2"

	_ = _string.append(_character)
	_ = "_string += _character"

	_ = _string.capitalized // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "capitalize"), [])

	_ = _string.uppercased() // gryphon pure
	_ = _GRYTemplate.call(.dot("_string", "toUpperCase"), [])

	_ = Substring(_string)
	_ = "_string"

	// Character
	_ = _character.uppercased() // gryphon pure
	_ = _GRYTemplate.call(.dot("_character", "toUpperCase"), [])

	// Array
	_ = _array.append(_any) // gryphon pure
	_ = _GRYTemplate.call(.dot("_array", "add"), ["_any"])

	_ = _array.insert(_any, at: _int) // gryphon pure
	_ = _GRYTemplate.call(.dot("_array", "add"), ["_int", "_any"])

	_ = _arrayOfOptionals.append(nil) // gryphon pure
	_ = _GRYTemplate.call(.dot("_arrayOfOptionals", "add"), ["null"])

	_ = _array1.append(contentsOf: _array2) // gryphon pure
	_ = _GRYTemplate.call(.dot("_array1", "addAll"), ["_array2"])

	_ = _array1.append(contentsOf: _array3) // gryphon pure
	_ = _GRYTemplate.call(.dot("_array1", "addAll"), ["_array3"])

	_ = _array.isEmpty // gryphon pure
	_ = _GRYTemplate.call(.dot("_array", "isEmpty"), [])

	_ = _strArray.joined(separator: _string) // gryphon pure
	_ = _GRYTemplate.call(
		.dot("_strArray", "joinToString"),
		[.labeledParameter("separator", "_string")])

	_ = _strArray.joined() // gryphon pure
	_ = _GRYTemplate.call(
		.dot("_strArray", "joinToString"),
		[.labeledParameter("separator", "\"\"")])

	_ = _array.count
	_ = _GRYTemplate.dot("_array", "size")

	_ = _array.indices
	_ = _GRYTemplate.dot("_array", "indices")

	_ = _array.startIndex
	_ = "0"

	_ = _array.endIndex
	_ = _GRYTemplate.dot("_array", "size")

	_ = _array.index(after: _int)
	_ = "_int + 1"

	_ = _array.index(before: _int)
	_ = "_int - 1"

	_ = _array.first // gryphon pure
	_ = _GRYTemplate.call(.dot("_array", "firstOrNull"), [])

	_ = _array.first(where: _closure3)
	_ = _GRYTemplate.call(.dot("_array", "find"), ["_closure3"])

	_ = _array.last(where: _closure3)
	_ = _GRYTemplate.call(.dot("_array", "findLast"), ["_closure3"])

	_ = _array.last // gryphon pure
	_ = _GRYTemplate.call(.dot("_array", "lastOrNull"), [])

	_ = _array.prefix(while: _closure3)
	_ = _GRYTemplate.call(.dot("_array", "takeWhile"), ["_closure3"])

	_ = _array.removeFirst()
	_ = _GRYTemplate.call(.dot("_array", "removeAt"), ["0"])

	_ = _array.remove(at: _int)
	_ = _GRYTemplate.call(.dot("_array", "removeAt"), ["_int"])

	_ = _array.removeAll()
	_ = "_array.clear()"

	_ = _array.dropFirst() // gryphon pure
	_ = _GRYTemplate.call(.dot("_array", "drop"), ["1"])

	_ = _array.dropFirst(_int) // gryphon pure
	_ = _GRYTemplate.call(.dot("_array", "drop"), ["_int"])

	_ = _array.dropLast() // gryphon pure
	_ = _GRYTemplate.call(.dot("_array", "dropLast"), ["1"])

	_ = _array.dropLast(_int) // gryphon pure
	_ = _GRYTemplate.call(.dot("_array", "dropLast"), ["_int"])

	_ = _array.map(_closure2)
	_ = _GRYTemplate.call(.dot("_array", "map"), ["_closure2"])

	_ = _array.flatMap(_closure6)
	_ = _GRYTemplate.call(.dot("_array", "flatMap"), ["_closure6"])

	_ = _array.compactMap(_closure2)
	_ = _GRYTemplate.call(.dot(.call(.dot("_array", "map"), ["_closure2"]), "filterNotNull"), [])

	_ = _array.filter(_closure3)
	_ = _GRYTemplate.call(.dot("_array", "filter"), ["_closure3"])

	_ = _array.reduce(_any, _closure)
	_ = _GRYTemplate.call(.dot("_array", "fold"), ["_any", "_closure"])

	_ = zip(_array1, _array2) // gryphon pure
	_ = _GRYTemplate.call(.dot("_array1", "zip"), ["_array2"])

	_ = _array.firstIndex(where: _closure3)
	_ = _GRYTemplate.call(.dot("_array", "indexOfFirst"), ["_closure3"])

	_ = _array.contains(where: _closure3)
	_ = "(" + _GRYTemplate.call(.dot("_array", "find"), ["_closure3"]) + " != null)"

	_ = _comparableArray.sorted() // gryphon pure
	_ = _GRYTemplate.call(.dot("_comparableArray", "sorted"), [])

	_ = _comparableArray.contains(_comparable) // gryphon pure
	_ = _GRYTemplate.call(.dot("_comparableArray", "contains"), ["_comparable"])

	_ = _comparableArray.firstIndex(of: _comparable) // gryphon pure
	_ = _GRYTemplate.call(.dot("_comparableArray", "indexOf"), ["_comparable"])

	// Dictionary
	_ = _dictionary.count
	_ = _GRYTemplate.dot("_dictionary", "size")

	_ = _dictionary.isEmpty // gryphon pure
	_ = _GRYTemplate.call(.dot("_dictionary", "isEmpty"), [])

	_ = _dictionary.map(_closure2)
	_ = _GRYTemplate.call(.dot("_dictionary", "map"), ["_closure2"])

	// Int
	_ = Int.max
	_ = _GRYTemplate.dot("Int", "MAX_VALUE")

	_ = Int.min
	_ = _GRYTemplate.dot("Int", "MIN_VALUE")

	_ = min(_int1, _int2) // gryphon pure
	_ = _GRYTemplate.call(.dot("Math", "min"), ["_int1", "_int2"])

	_ = _int1..._int2
	_ = "_int1.._int2"

	_ = _int1..<_int2
	_ = "_int1 until _int2"

	// Double
	_ = _double1..._double2 // gryphon pure
	_ = _GRYTemplate.call(.dot("(_double1)", "rangeTo"), ["_double2"])

	// Optional
	_ = _optional.map(_closure4)
	_ = _GRYTemplate.call(.dot("_optional?", "let"), ["_closure4"])
}

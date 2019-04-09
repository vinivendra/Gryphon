
import Foundation

struct Hash: Hashable { }
struct Compare: Comparable {
	static func < (lhs: Compare, rhs: Compare) -> Bool {
		return false
	}
}

func gryphonTemplates() {
	var _strArray: [String] = []
	var _array: [Any] = []
	var _array1: [Any] = []
	var _array2: [Any] = []
	var _comparableArray : [Compare] = []
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
	let _double: Double = 0
	let _double1: Double = 0
	let _double2: Double = 0
	let _int: Int = 0
	let _int1: Int = 0
	let _int2: Int = 0
	let _dictionary: [Hash: Any] = [:]
	let _closure: (Any, Any) -> Any = { a, b in a }
	let _closure2: (Any) -> Any = { a in a }
	let _closure3: (Any) -> Bool = { _ in true }

	// Print
	print(_any)
	"println(_any)"

	print(_any, terminator: "")
	"print(_any)"

	// Darwin
	sqrt(_double)
	"Math.sqrt(_double)"

	// String
	_string.isEmpty
	"_string.isEmpty()"

	_string.count
	"_string.length"

	Double(_string)
	"_string.toDouble()"

	_string.dropLast()
	"_string.dropLast(1)"

	_string.indices
	"_string.indices"

	_string.prefix(_int)
	"_string.substring(0, _int)"

	_string[_index...]
	"_string.substring(_index)"

	_string[_index1..<_index2]
	"_string.substring(_index1, _index2)"

	_string[_index1..._index2]
	"_string.substring(_index1, _index2 + 1)"

	String(_substring)
	"_substring"

	_string.endIndex
	"_string.length"

	_string.startIndex
	"0"

	_string.formIndex(before: &_index)
	"_index -= 1"

	_string.index(after: _index)
	"_index + 1"

	_string.index(before: _index)
	"_index - 1"

	_string.index(_index, offsetBy: _int)
	"_index + _int"

	_substring.index(_index, offsetBy: _int)
	"_index + _int"

	_string1.replacingOccurrences(of: _string2, with: _string3)
	"_string1.replace(_string2, _string3)"

	_string1.hasPrefix(_string2)
	"_string1.startsWith(_string2)"

	_range.lowerBound
	"_range.start"

	_range.upperBound
	"_range.endInclusive"

	Range<String.Index>(uncheckedBounds: (lower: _index1, upper: _index2))
	"IntRange(_index1, _index2)"

	_string1.append(_string2)
	"_string1 += _string2"

	_string.append(_character)
	"_string += _character"

	// Character

	_character.uppercased()
	"_character.toUpperCase()"

	// Array
	_array.append(_any)
	"_array.add(_any)"

	_array1.append(contentsOf: _array2)
	"_array1.addAll(_array2)"

	_array.isEmpty
	"_array.isEmpty()"

	_strArray.joined(separator: _string)
	"_strArray.joinToString(separator = _string)"

	_array.count
	"_array.size"

	_array.first
	"_array.firstOrNull()"

	_array.first(where: _closure3)
	"_array.find _closure3"

	_array.last
	"_array.lastOrNull()"

	_array.dropFirst()
	"_array.drop(1)"

	_array.dropLast()
	"_array.dropLast(1)"

	_array.map(_closure2)
	"_array.map _closure2.toMutableList()"

	_comparableArray.sorted()
	"_comparableArray.sorted()"

	// Dictionary
	_dictionary.reduce(_any, _closure)
	"_dictionary.entries.fold(initial = _any, operation = _closure)"

	_dictionary.map(_closure2)
	"_dictionary.map _closure2.toMutableList()"

	// Int
	Int.max
	"Int.MAX_VALUE"

	Int.min
	"Int.MIN_VALUE"

	min(_int1, _int2)
	"Math.min(_int1, _int2)"

	_int1..._int2
	"_int1.._int2"

	_int1..<_int2
	"_int1 until _int2"

	// Double
	_double1..._double2
	"(_double1).rangeTo(_double2)"
}

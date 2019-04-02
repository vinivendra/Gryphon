
import Foundation

struct Hash: Hashable { }

var _strArray: [String] = []
var _array: [Any] = []
let _index: String.Index = "".startIndex
let _index1: String.Index = "".startIndex
let _index2: String.Index = "".startIndex
let _string: String = ""
let _string1: String = ""
let _string2: String = ""
let _string3: String = ""
let _substring: Substring = " ".dropLast()
let _any: Any = ""
let _double: Double = 0
let _double1: Double = 0
let _double2: Double = 0
let _int: Int = 0
let _int1: Int = 0
let _int2: Int = 0
let _dictionary: [Hash: Any] = [:]
let _closure: (Any, Any) -> Any = { a, b in a }

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

_string.prefix(_int)
"_string.substring(0, _int)"

_string[_index...]
"_string.substring(_index)"

_string[_index1..<_index2]
"_string.substring(_index1, _index2)"

String(_substring)
"_substring"

_string.endIndex
"_string.length"

_string.startIndex
"0"

_string.index(after: _index)
"_index + 1"

_string1.replacingOccurrences(of: _string2, with: _string3)
"_string1.replace(_string2, _string3)"

// Array
_array.append(_any)
"_array.add(_any)"

_array.isEmpty
"_array.isEmpty()"

_strArray.joined(separator: _string)
"_strArray.joinToString(separator = _string)"

_array.count
"_array.size"

_array.last
"_array.lastOrNull()"

_array.dropLast()
"_array.dropLast(1)"

// Dictionary
_dictionary.reduce(_any, _closure)
"_dictionary.entries.fold(initial = _any, operation = _closure)"

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

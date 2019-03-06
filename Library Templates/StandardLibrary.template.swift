
import Foundation

struct Hash: Hashable { }

var _strArray: [String] = []
var _array: [Any] = []
let _string = ""
let _any: Any = ""
let _double: Double = 0
let _int: Int = 0
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

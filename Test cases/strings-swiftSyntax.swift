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

// gryphon output: Test cases/Bootstrap Outputs/strings.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/strings.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/strings.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/strings.kt

// String Literal
let x = "Hello, world!"
let y = "The string above is \(x)"
let z = 0
let w = "Here's another interpolated string: \(x), \(y) and \(z)"

let escapedString = "A string with \"escaped double quotes\" \\ and escaped backslashes\n\t and some escaped characters too."

let singleInterpolation = "\(x)"
let interpolationWithDoubleQuotes = "\"\"\(x)"

print(x)
print(y)
print(z)
print(w)
print(escapedString)
print(singleInterpolation)
print(interpolationWithDoubleQuotes)

// Multiline
let multilineString1 = """

This is a multiline string.
It has many lines.

"""

let multilineString2 = """
This multiline string has less whitespace.
It still has many lines.
"""

let multilineString3 = """

		This multiline string has indentation.
		It also has many lines.

"""

func f() {
	let multilineString = """

		This multiline string has nested indentation.
		And it has many lines.

	"""
	print(multilineString)
}

print("==")
print(multilineString1)
print("==")
print(multilineString2)
print("==")
print(multilineString3)
print("==")
f()
print("==")

// Characters
let character: Character = "i"

print(character)

// String indices
let abc = "abc"
for index in abc.indices {
	print(abc[index])
}
for char in abc {
	print(char)
}

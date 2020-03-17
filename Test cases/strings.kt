//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
internal fun f() {
	// gryphon multiline
	val multilineString: String = """
	This multiline string has nested indentation.
	And it has many lines.
"""
	println(multilineString)
}

fun main(args: Array<String>) {
	val x: String = "Hello, world!"
	val y: String = "The string above is ${x}"
	val z: Int = 0
	val w: String = "Here's another interpolated string: ${x}, ${y} and ${z}"
	val escapedString: String = "A string with \"escaped double quotes\" \\ and escaped backslashes\n\t and some escaped characters too."
	val singleInterpolation: String = "${x}"
	val interpolationWithDoubleQuotes: String = "\"\"${x}"

	println(x)
	println(y)
	println(z)
	println(w)
	println(escapedString)
	println(singleInterpolation)
	println(interpolationWithDoubleQuotes)

	val multilineString1: String = """
This is a multiline string.
It has many lines.
"""
	val multilineString2: String = """This multiline string has less whitespace.
It still has many lines."""
	val multilineString3: String = """
		This multiline string has indentation.
		It also has many lines.
"""

	println("==")
	println(multilineString1)
	println("==")
	println(multilineString2)
	println("==")
	println(multilineString3)
	println("==")

	f()

	println("==")

	val character: Char = 'i'

	println(character)
}

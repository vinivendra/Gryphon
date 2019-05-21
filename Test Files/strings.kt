//
// Copyright 2018 Vinícius Jorge Vendramini
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

fun main(args: Array<String>) {
	val x: String = "Hello, world!"
	val y: String = "The string above is ${x}"
	val z: Int = 0
	val w: String = "Here's another interpolated string: ${x}, ${y} and ${z}"
	val escapedString: String = "A string with \"escaped double quotes\" \\ and escaped backslashes \n\t and some escaped characters too."
	val singleInterpolation: String = "${x}"
	val interpolationWithDoubleQuotes: String = "\"\"${x}"
}

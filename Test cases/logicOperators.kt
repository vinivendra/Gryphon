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

fun main(args: Array<String>) {
	val t: Boolean = true
	val f: Boolean = false
	var x: Boolean = t || f
	var y: Boolean = t && f

	println("${x}")
	println("${y}")

	x = f || f
	y = f && f

	println("${x}")
	println("${y}")
	println("${t || t}")
	println("${t && t}")
	println("${true || false}")
	println("${true && false}")

	x = true || false

	println("${x}")

	var z: Boolean = !x

	println("${z}")

	z = !y

	println("${z}")

	if (x) {
		println("true")
	}

	if (!x) {
		println("false")
	}

	if (t && (!f) || f) {
		println("true")
	}
}

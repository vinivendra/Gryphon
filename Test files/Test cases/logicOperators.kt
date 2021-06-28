//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
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
		// Will get printed
		println("true")
	}

	if (!x) {
		// Won't get printed
		println("false")
	}

	if (t && (!f) || f) {
		// Will get printed
		println("true")
	}
}

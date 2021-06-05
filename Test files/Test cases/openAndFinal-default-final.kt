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
internal class A {
	companion object {
		var a7: Int = 0

		fun b7() {
		}
	}

	// Open by default, final if compiled with -default-final
	var a1: Int = 0

	fun b1() {
	}

	// Overriding with annotations
	open var a2: Int = 0

	open fun b2() {
	}

	var a3: Int = 0

	fun b3() {
	}

	// Swift annotations
	open var a4: Int = 0

	open fun b4() {
	}

	var a5: Int = 0

	fun b5() {
	}

	// Private declarations can't be open
	private var a6: Int = 0

	private fun b6() {
	}

	// Static declarations can't be open
	// Let declarations can't be open
	val a8: Int = 0

	// Subscripts
	operator open fun get(i: Int): Int {
		return i
	}

	operator fun get(j: String): String {
		return j
	}
}

internal class A1 {
}

internal open class A2 {
}

internal class A3 {
}

private class A4 {
}

open class A5 {
}

internal data class B(
	val a1: Int = 0,
	open val a2: Int = 0
) {
	companion object {
		var a3: Int = 0

		fun b3() {
		}
	}

	// Declarations for value types are static by default
	fun b1() {
	}

	// Override with annotations
	open fun b2() {
	}

	// Test static declarations
}

internal enum class C {
	;

	companion object {
		var a3: Int = 0

		fun b3() {
		}
	}

	// Declarations for value types are static by default
	fun b1() {
	}

	// Override with annotations
	open fun b2() {
	}

	// Test static declarations
}

internal fun b1() {
}

fun main(args: Array<String>) {
	var a1: Int = 0
}

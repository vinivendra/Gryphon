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
internal open class A {
	companion object {
		var a7: Int = 0

		fun b7() {
		}
	}

	// Open by default, final if compiled with -default-final
	open var a1: Int = 0

	open fun b1() {
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
}

internal open class A1 {
}

internal open class A2 {
}

internal class A3 {
}

private class A4 {
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

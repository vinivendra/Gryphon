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
internal open class A1 {
	var a1: Int = 0
	var a2: Int = 0
	var a3: Int = 0
	var a4: Int = 0
	private var a5: Int = 0

	fun b1() {
	}

	fun b2() {
	}

	fun b3() {
	}

	fun b4() {
	}

	private fun b5() {
	}
}

open class A2 {
	internal var a1: Int = 0
	var a2: Int = 0
	internal var a3: Int = 0
	internal var a4: Int = 0
	private var a5: Int = 0

	internal fun b1() {
	}

	fun b2() {
	}

	internal fun b3() {
	}

	internal fun b4() {
	}

	private fun b5() {
	}
}

internal open class A3 {
	var a1: Int = 0
	var a2: Int = 0
	var a3: Int = 0
	var a4: Int = 0
	private var a5: Int = 0

	fun b1() {
	}

	fun b2() {
	}

	fun b3() {
	}

	fun b4() {
	}

	private fun b5() {
	}
}

private open class A4 {
	var a1: Int = 0
	var a2: Int = 0
	var a3: Int = 0
	var a4: Int = 0
	var a5: Int = 0

	fun b1() {
	}

	fun b2() {
	}

	fun b3() {
	}

	fun b4() {
	}

	fun b5() {
	}
}

private open class A5 {
	var a1: Int = 0
	var a2: Int = 0
	var a3: Int = 0
	var a4: Int = 0
	var a5: Int = 0

	fun b1() {
	}

	fun b2() {
	}

	fun b3() {
	}

	fun b4() {
	}

	fun b5() {
	}
}

internal open class A6 {
	companion object {
		var a1: Int = 0
		var a2: Int = 0
		var a3: Int = 0
		var a4: Int = 0
		private var a5: Int = 0

		fun b1() {
		}

		fun b2() {
		}

		fun b3() {
		}

		fun b4() {
		}

		private fun b5() {
		}
	}
}

open class A7 {
	companion object {
		internal var a1: Int = 0
		var a2: Int = 0
		internal var a3: Int = 0
		internal var a4: Int = 0
		private var a5: Int = 0

		internal fun b1() {
		}

		fun b2() {
		}

		internal fun b3() {
		}

		internal fun b4() {
		}

		private fun b5() {
		}
	}
}

internal open class A8 {
	companion object {
		var a1: Int = 0
		var a2: Int = 0
		var a3: Int = 0
		var a4: Int = 0
		private var a5: Int = 0

		fun b1() {
		}

		fun b2() {
		}

		fun b3() {
		}

		fun b4() {
		}

		private fun b5() {
		}
	}
}

private open class A9 {
	companion object {
		var a1: Int = 0
		var a2: Int = 0
		var a3: Int = 0
		var a4: Int = 0
		var a5: Int = 0

		fun b1() {
		}

		fun b2() {
		}

		fun b3() {
		}

		fun b4() {
		}

		fun b5() {
		}
	}
}

private open class A10 {
	companion object {
		var a1: Int = 0
		var a2: Int = 0
		var a3: Int = 0
		var a4: Int = 0
		var a5: Int = 0

		fun b1() {
		}

		fun b2() {
		}

		fun b3() {
		}

		fun b4() {
		}

		fun b5() {
		}
	}
}

internal data class B1(
	val a1: Int = 0,
	val a2: Int = 0,
	val a3: Int = 0,
	val a4: Int = 0,
	private val a5: Int = 0
) {
	fun b1() {
	}

	fun b2() {
	}

	fun b3() {
	}

	fun b4() {
	}

	private fun b5() {
	}
}

data class B2(
	internal val a1: Int = 0,
	val a2: Int = 0,
	internal val a3: Int = 0,
	internal val a4: Int = 0,
	private val a5: Int = 0
) {
	internal fun b1() {
	}

	fun b2() {
	}

	internal fun b3() {
	}

	internal fun b4() {
	}

	private fun b5() {
	}
}

internal data class B3(
	val a1: Int = 0,
	val a2: Int = 0,
	val a3: Int = 0,
	val a4: Int = 0,
	private val a5: Int = 0
) {
	fun b1() {
	}

	fun b2() {
	}

	fun b3() {
	}

	fun b4() {
	}

	private fun b5() {
	}
}

private data class B4(
	val a1: Int = 0,
	val a2: Int = 0,
	val a3: Int = 0,
	val a4: Int = 0,
	val a5: Int = 0
) {
	fun b1() {
	}

	fun b2() {
	}

	fun b3() {
	}

	fun b4() {
	}

	fun b5() {
	}
}

private data class B5(
	val a1: Int = 0,
	val a2: Int = 0,
	val a3: Int = 0,
	val a4: Int = 0,
	val a5: Int = 0
) {
	fun b1() {
	}

	fun b2() {
	}

	fun b3() {
	}

	fun b4() {
	}

	fun b5() {
	}
}

internal enum class C1 {
	A;

	val a1: Int
		get() {
			return 0
		}
	val a2: Int
		get() {
			return 0
		}
	val a3: Int
		get() {
			return 0
		}
	val a4: Int
		get() {
			return 0
		}
	private val a5: Int
		get() {
			return 0
		}

	fun b1() {
	}

	fun b2() {
	}

	fun b3() {
	}

	fun b4() {
	}

	private fun b5() {
	}
}

 enum class C2 {
	A;

	internal val a1: Int
		get() {
			return 0
		}
	val a2: Int
		get() {
			return 0
		}
	internal val a3: Int
		get() {
			return 0
		}
	internal val a4: Int
		get() {
			return 0
		}
	private val a5: Int
		get() {
			return 0
		}

	internal fun b1() {
	}

	fun b2() {
	}

	internal fun b3() {
	}

	internal fun b4() {
	}

	private fun b5() {
	}
}

internal enum class C3 {
	A;

	val a1: Int
		get() {
			return 0
		}
	val a2: Int
		get() {
			return 0
		}
	val a3: Int
		get() {
			return 0
		}
	val a4: Int
		get() {
			return 0
		}
	private val a5: Int
		get() {
			return 0
		}

	fun b1() {
	}

	fun b2() {
	}

	fun b3() {
	}

	fun b4() {
	}

	private fun b5() {
	}
}

private enum class C4 {
	A;

	val a1: Int
		get() {
			return 0
		}
	val a2: Int
		get() {
			return 0
		}
	val a3: Int
		get() {
			return 0
		}
	val a4: Int
		get() {
			return 0
		}
	val a5: Int
		get() {
			return 0
		}

	fun b1() {
	}

	fun b2() {
	}

	fun b3() {
	}

	fun b4() {
	}

	fun b5() {
	}
}

private enum class C5 {
	A;

	val a1: Int
		get() {
			return 0
		}
	val a2: Int
		get() {
			return 0
		}
	val a3: Int
		get() {
			return 0
		}
	val a4: Int
		get() {
			return 0
		}
	val a5: Int
		get() {
			return 0
		}

	fun b1() {
	}

	fun b2() {
	}

	fun b3() {
	}

	fun b4() {
	}

	fun b5() {
	}
}

internal interface D1 {
	val a: Int

	fun b() {

	}
}

interface D2 {
	val a: Int

	fun b() {

	}
}

internal interface D3 {
	val a: Int

	fun b() {

	}
}

private interface D4 {
	val a: Int

	fun b() {

	}
}

private interface D5 {
	val a: Int

	fun b() {

	}
}

internal val String.a1: Int
	get() {
		return 0
	}
val String.a2: Int
	get() {
		return 0
	}
internal val String.a3: Int
	get() {
		return 0
	}
private val String.a4: Int
	get() {
		return 0
	}
private val String.a5: Int
	get() {
		return 0
	}

internal fun String.b1() {
}

fun String.b2() {
}

internal fun String.b3() {
}

private fun String.b4() {
}

private fun String.b5() {
}

open class A11 {
	public var a1: Int = 0
	internal var a2: Int = 0
	protected var a3: Int = 0
	private var a4: Int = 0

	public fun b1() {
	}

	internal fun b2() {
	}

	protected fun b3() {
	}

	private fun b4() {
	}
}

fun main(args: Array<String>) {
	var a1: Int = 0
	var a2: Int = 0
	var a3: Int = 0
	var a4: Int = 0
	var a5: Int = 0
}

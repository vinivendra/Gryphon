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
internal open class A1 {
	open var a1: Int = 0
	open var a2: Int = 0
	open var a3: Int = 0
	open var a4: Int = 0
	private var a5: Int = 0

	open fun b1() {
	}

	open fun b2() {
	}

	open fun b3() {
	}

	open fun b4() {
	}

	private fun b5() {
	}

	constructor(c1: Int) {
	}

	constructor(c2: Double) {
	}

	constructor(c3: Float) {
	}

	constructor(c4: String) {
	}

	private constructor(c5: Boolean) {
	}
}

open class A2 {
	internal open var a1: Int = 0
	open var a2: Int = 0
	internal open var a3: Int = 0
	internal open var a4: Int = 0
	private var a5: Int = 0

	internal open fun b1() {
	}

	open fun b2() {
	}

	internal open fun b3() {
	}

	internal open fun b4() {
	}

	private fun b5() {
	}

	internal constructor(c1: Int) {
	}

	constructor(c2: Double) {
	}

	internal constructor(c3: Float) {
	}

	internal constructor(c4: String) {
	}

	private constructor(c5: Boolean) {
	}
}

internal open class A3 {
	open var a1: Int = 0
	open var a2: Int = 0
	open var a3: Int = 0
	open var a4: Int = 0
	private var a5: Int = 0

	open fun b1() {
	}

	open fun b2() {
	}

	open fun b3() {
	}

	open fun b4() {
	}

	private fun b5() {
	}

	constructor(c1: Int) {
	}

	constructor(c2: Double) {
	}

	constructor(c3: Float) {
	}

	constructor(c4: String) {
	}

	private constructor(c5: Boolean) {
	}
}

private class A4 {
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

	constructor(c1: Int) {
	}

	constructor(c2: Double) {
	}

	constructor(c3: Float) {
	}

	constructor(c4: String) {
	}

	constructor(c5: Boolean) {
	}
}

private class A5 {
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

	constructor(c1: Int) {
	}

	constructor(c2: Double) {
	}

	constructor(c3: Float) {
	}

	constructor(c4: String) {
	}

	constructor(c5: Boolean) {
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

private class A9 {
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

private class A10 {
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

	fun b()
}

interface D2 {
	val a: Int

	fun b()
}

internal interface D3 {
	val a: Int

	fun b()
}

private interface D4 {
	val a: Int

	fun b()
}

private interface D5 {
	val a: Int

	fun b()
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

open class E1 {
	public open var a1: Int = 0
	internal open var a2: Int = 0
	protected open var a3: Int = 0
	private var a4: Int = 0

	public open fun b1() {
	}

	internal open fun b2() {
	}

	protected open fun b3() {
	}

	private fun b4() {
	}

	public constructor(c1: Int) {
	}

	internal constructor(c2: Double) {
	}

	protected constructor(c3: Float) {
	}

	private constructor(c4: String) {
	}
}

public interface E2 {
	val a: Int

	fun b()
}

public enum class E3 {
	A;
}

public data class E4(
	internal val a: Int = 0
)

public open class E5 {
}

internal open class E6 {
	protected open class Nested {
		open var a1: Int = 0
		open var a2: Int = 0
		open var a3: Int = 0
		open var a4: Int = 0
	}
}

fun main(args: Array<String>) {
	var a1: Int = 0
	var a2: Int = 0
	var a3: Int = 0
	var a4: Int = 0
	var a5: Int = 0
}

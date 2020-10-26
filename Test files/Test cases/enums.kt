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
internal sealed class CalculatorError: Exception() {
	class InvalidCharacter: CalculatorError()
	class MultipleCharacters: CalculatorError()
	class NilInput: CalculatorError()
}

internal sealed class OtherError: Exception() {
	class OneInt(val int: Int): OtherError()
	class TwoInts(val int: Int, val int2: Int): OtherError()
	class IntAndString(val int: Int, val string: String): OtherError()
}

internal enum class NoInheritances {
	FOO_BAR,
	BAR_BAZ;

	companion object {
		operator fun invoke(rawValue: String): NoInheritances? {
			return when (rawValue) {
				"foo-bar" -> NoInheritances.FOO_BAR
				"barBaz" -> NoInheritances.BAR_BAZ
				else -> null
			}
		}
	}

	val rawValue: String
		get() {
			return when (this) {
				NoInheritances.FOO_BAR -> "foo-bar"
				NoInheritances.BAR_BAZ -> "barBaz"
			}
		}
}

internal enum class WithMembers {
	FOO_BAR,
	BAZ;

	fun a() {
	}

	fun b() {
	}
}

internal fun throwingFunc() {
	throw CalculatorError.InvalidCharacter()
}

internal fun otherThrowingFunc() {
	throwingFunc()
}

enum class MyEnum {
	FOO_BAR,
	BAZ;
}

val a = MyEnum.FOO_BAR
val b = MyEnum.BAZ

open class K {
	sealed class A {
		class B(val int: Int): A()

		internal fun foo(): Int {
			return when (this) {
				is A.B -> {
					val int: Int = this.int
					0
				}
			}
		}
	}
}

fun main(args: Array<String>) {
	if (a == MyEnum.FOO_BAR) {
		println("MyEnum.FOO_BAR")
	}

	if (b == MyEnum.BAZ) {
		println("MyEnum.BAZ")
	}

	val c: K.A = K.A.B(int = 0)
}

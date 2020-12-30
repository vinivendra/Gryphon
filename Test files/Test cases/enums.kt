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

internal enum class NoInheritances(val rawValue: String) {
	FOO_BAR(rawValue = "foo-bar"),
	BAR_BAZ(rawValue = "barBaz");

	companion object {
		operator fun invoke(rawValue: String): NoInheritances? = values().firstOrNull { it.rawValue == rawValue }
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

internal enum class E1(val rawValue: Int) {
	A(rawValue = 0),
	B(rawValue = 1);

	companion object {
		operator fun invoke(rawValue: Int): E1? = values().firstOrNull { it.rawValue == rawValue }
	}
}

internal enum class E2(val rawValue: String) {
	A(rawValue = "a"),
	A_B(rawValue = "aB");

	companion object {
		operator fun invoke(rawValue: String): E2? = values().firstOrNull { it.rawValue == rawValue }
	}
}

internal enum class E3(val rawValue: Int) {
	A(rawValue = 10),
	B(rawValue = 100),
	C(rawValue = 101);

	companion object {
		operator fun invoke(rawValue: Int): E3? = values().firstOrNull { it.rawValue == rawValue }
	}
}

internal enum class E4(val rawValue: String) {
	A(rawValue = "aaA"),
	A_B(rawValue = "B_A"),
	C(rawValue = "c");

	companion object {
		operator fun invoke(rawValue: String): E4? = values().firstOrNull { it.rawValue == rawValue }
	}
}

fun main(args: Array<String>) {
	val a = MyEnum.FOO_BAR
	val b = MyEnum.BAZ

	if (a == MyEnum.FOO_BAR) {
		println("MyEnum.FOO_BAR")
	}

	if (b == MyEnum.BAZ) {
		println("MyEnum.BAZ")
	}

	val c: K.A = K.A.B(0)

	println(E1.B.rawValue)
	println(E2.A_B.rawValue)
	println(E3.A.rawValue)
	println(E3.C.rawValue)
	println(E4.A.rawValue)
	println(E4.C.rawValue)
}

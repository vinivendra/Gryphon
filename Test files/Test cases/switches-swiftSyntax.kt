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
internal fun printNumberName(x: Int) {
	when (x) {
		0 -> println("Zero")
		1 -> println("One")
		2 -> println("Two")
		3 -> println("Three")
		in 4..5 -> println("Four or five")
		in 6 until 10 -> println("Less than ten")
		else -> println("Dunno!")
	}
}

internal fun getNumberName(x: Int): String {
	return when (x) {
		0 -> "Zero"
		1 -> "One"
		2 -> "Two"
		3 -> "Three"
		else -> "Dunno!"
	}
}

internal enum class MyEnum {
	A,
	B,
	C,
	D,
	E;
}

internal sealed class MySealedClass {
	class A(val int: Int): MySealedClass()
	class B: MySealedClass()
}

internal fun g(i: Int) {
	when (i) {
		0, 1, 2 -> println("Low")
		else -> println("High")
	}
}

internal fun f() {
	val number: Int = 0
	val name: String = when (number) {
		0 -> "Zero"
		else -> "More"
	}
}

fun main(args: Array<String>) {
	printNumberName(x = 0)
	printNumberName(x = 1)
	printNumberName(x = 2)
	printNumberName(x = 3)
	printNumberName(x = 4)
	printNumberName(x = 7)
	printNumberName(x = 10)
	println(getNumberName(x = 0))
	println(getNumberName(x = 1))
	println(getNumberName(x = 2))
	println(getNumberName(x = 3))
	println(getNumberName(x = 4))

	var y: Int = 0

	var x: Int = when (y) {
		0 -> 10
		else -> 20
	}

	println(x)

	x = when (y) {
		0 -> 100
		else -> 200
	}

	println(x)

	val myEnum: MyEnum = MyEnum.A

	when (myEnum) {
		MyEnum.A -> println("It's a!")
		else -> println("It's not a.")
	}

	val mySealedClass: MySealedClass = MySealedClass.A(int = 0)

	when (mySealedClass) {
		is MySealedClass.A -> {
			val int: Int = mySealedClass.int
			println(int)
		}
		is MySealedClass.B -> println("b")
	}

	g(i = 0)
	g(i = 1)
	g(i = 2)
	g(i = 3)

	val z: Int = 0

	when (z) {
		0 -> {
		}
		1 -> println(1)
		else -> println(2)
	}
}

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
internal fun useClosure(closure: (String) -> Unit) {
	closure("Calling from function!")
}

internal fun defaultClosure(closure: (String) -> Unit = { println(it) }) {
	closure("Calling from default closure!")
}

internal fun f(closure: () -> Int, a: Int) {
}

internal fun g(closure: () -> Int, a: Int = 0, c: Int) {
}

internal fun f1(closure: () -> Int) {
}

internal fun f2(a: Int, closure: () -> Int) {
}

internal fun g1(closure: () -> Int, a: Int = 0) {
}

internal fun g2(a: Int = 0, closure: () -> Int) {
}

internal fun f3(closure: () -> Unit) {
}

internal fun f4(closure: () -> Unit) {
}

internal fun bar(closure: () -> Int) {
}

internal open class A {
	open fun bar(closure: () -> Int) {
	}
}

internal data class B(
	val closure: () -> Int
)

internal fun Int.bar(closure: (Int) -> Int): Int {
	return closure(this)
}

internal fun Int.foo(closure: (Int) -> Int): Int {
	return closure(this)
}

internal fun foo(closure: (Int) -> Int) {
}

fun main(args: Array<String>) {
	val printClosure: (String) -> Unit = { println(it) }

	printClosure("Hello, world!")

	val plusClosure: (Int, Int) -> Int = { a, b -> a + b }

	println(plusClosure(2, 3))
	useClosure(closure = printClosure)
	defaultClosure()

	val multiLineClosure: (Int) -> Unit = { a ->
			if (a == 10) {
				println("It's ten!")
			}
			else {
				println("It's not ten.")
			}
		}

	multiLineClosure(10)
	multiLineClosure(20)
	f({ 0 }, a = 0)
	g(closure = { 0 }, c = 0)
	f1 { 0 }
	f2(a = 0) { 0 }
	g1(closure = { 0 })
	g2(closure = { 0 })
	f3 { }
	f4 { }
	bar {
			if (true) {
				return@bar 1
			}
			else {
				return@bar 0
			}
		}
	A().bar {
			if (true) {
				return@bar 1
			}
			else {
				return@bar 0
			}
		}
	B {
			if (true) {
				return@B 1
			}
			else {
				return@B 0
			}
		}
	0.bar { a ->
			if (true) {
				return@bar a + 1
			}

			return@bar a + 1
		}.foo { b ->
			if (true) {
				return@foo b + 1
			}

			return@foo b + 1
		}
	foo {
			when (it) {
				0 -> 0
				else -> 1
			}
		}
	foo { bla ->
			if (true) {
				return@foo 0
			}
			else {
				return@foo 1
			}
		}
}

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
internal open class A {
	open var x: Int = 0

	operator open fun get(i: Int): Int {
		return x + i
	}

	operator open fun set(i: Int, newValue: Int) {
		this.x = newValue + 1
	}
}

internal open class B {
	operator open fun get(i: Int): Int {
		return i
	}
}

internal open class C {
	operator open fun get(b: Int): Int {
		return b
	}
}

internal open class D {
	operator open fun get(a: Int, b: Int): Int {
		return a + b
	}

	operator open fun set(a: Int, b: Int, newValue: Int) {
		println("${a} ${b} ${newValue}")
	}
}

internal open class E {
	operator open fun get(b: Int, d: Int): Int {
		return b + d
	}

	operator open fun set(b: Int, d: Int, newValue: Int) {
		println("${b} ${d} ${newValue}")
	}
}

fun main(args: Array<String>) {
	val a: A = A()

	a[1] = 10

	println(a[1])

	val b: B = B()

	println(b[1])

	val c: C = C()

	println(c[0])

	val d: D = D()

	println(d[0, 1])

	d[0, 1] = 2

	val e: E = E()

	println(e[0, 1])

	e[0, 1] = 2

	val a1: A? = A()

	println(a1?.get(1))

	val b1: B? = B()

	println(b1?.get(1))

	val c1: C? = C()

	println(c1?.get(0))

	val d1: D? = D()

	println(d1?.get(0, 1))

	val e1: E? = E()

	println(e1?.get(0, 1))
}

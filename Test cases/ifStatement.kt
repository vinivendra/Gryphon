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
internal fun trueFunction(): Boolean {
	return true
}

internal fun testGuards() {
	val x: Int = 0

	if (x != 0) {
		println("--")
		return
	}

	if (x == 1) {
		println("--")
		return
	}

	if (false) {
		println("--")
		return
	}

	println("Guard")
}

internal fun bla(): Int? {
	return 0
}

internal enum class A {
	A1,
	A2;
}

internal sealed class B {
	class C(val d: Int): B()
	class E(val f: Int, val g: String): B()
}

internal open class C {
	open var c: C? = null
	open var x: Int = 0
}

fun main(args: Array<String>) {
	if (true) {
		println("Simple if's")
	}

	if (false) {
		println("--")
	}

	if (trueFunction()) {
		println("If with a function")
	}

	if (true) {
		println("Simple, with empty else if and else")
	}
	else {
	}

	if (true) {
		println("Simple, with empty else if and else #2")
	}
	else if (true) {
	}
	else {
	}

	if (true) {
		println("Simple, with empty else if and else #3")
	}
	else if (true) {
	}
	else if (true) {
	}
	else {
	}

	if (trueFunction()) {
		println("Else if and else with contents")
	}
	else if (trueFunction()) {
		println("--")
	}
	else {
		println("--")
	}

	if (trueFunction()) {
		println("Else if and else with contents #2")
	}
	else if (trueFunction()) {
		println("--")
	}
	else if (trueFunction()) {
		println("--")
	}
	else {
		println("--")
	}

	if (false) {
		println("--")
	}
	else if (true) {
		println("Else if and else with contents that get executed")
	}
	else {
		println("--")
	}

	if (false) {
		println("--")
	}
	else if (false) {
		println("--")
	}
	else {
		println("Else if and else with contents that get executed #2")
	}

	testGuards()

	val x: Int? = 0
	val y: Int? = 0
	val z: Int? = null
	val a: Int? = x

	if (a != null) {
		println("${a}")
		println("If let")
	}

	val b: Int? = x

	if (b != null) {
		println("${b}")
		println("If let #2")
	}
	else if (x == 0) {
		println("--")
	}
	else {
		println("--")
	}

	val c: Int? = z

	if (c != null) {
		println("--")
	}
	else {
		println("${z}")
		println("If let #3")
	}

	val f: Int? = bla()
	var d: Int? = x
	val e: Int? = y

	if (f != null && d != null && e != null && x == 0) {
		println("${d}, ${e}, ${f}, ${x!!}")
		println("If let #4")
	}
	else if (x == 1) {
		println("--")
	}
	else {
		println("--")
	}

	if (x != null) {
		println("If let #5")
	}

	val aEnum1: A = A.A1
	val aEnum2: A = A.A2

	if (aEnum1 == A.A1) {
		println("If case #1")
	}

	if (aEnum1 == A.A2) {
		println("--")
	}

	if (aEnum2 == A.A1) {
		println("--")
	}

	if (aEnum2 == A.A2) {
		println("If case #2")
	}

	val bEnum: B = B.C(d = 0)
	val bEnum2: B = B.E(f = 0, g = "foo")

	if (bEnum is B.C) {
		println("If case let #1")
	}

	if (bEnum is B.C) {
		val foo: Int = bEnum.d
		println("If case let #2: ${foo}")
	}

	if (bEnum is B.E) {
		val foo: Int = bEnum.f
		val bar: String = bEnum.g
		println("--")
	}

	if (bEnum2 is B.E) {
		val foo: Int = bEnum2.f
		val bar: String = bEnum2.g
		println("If case let #3: ${foo}, ${bar}")
	}

	if (bEnum2 is B.E) {
		val bar: String = bEnum2.g
		println("If case let #4: ${bar}")
	}

	if (bEnum2 is B.E) {
		val foo: Int = bEnum2.f
		println("If case let #5: ${foo}")
	}

	if (bEnum2 is B.E) {
		println("If case let #6")
	}

	if (false) {
		println("--")
	}
	else if (bEnum is B.C) {
		val foo: Int = bEnum.d
		println("If case let #7: ${foo}")
	}
	else if (bEnum2 is B.E) {
		val foo: Int = bEnum2.f
		val bar: String = bEnum2.g
		println("--")
	}

	if (false) {
		println("--")
	}
	else if (bEnum2 is B.E) {
		val foo: Int = bEnum2.f
		val bar: String = bEnum2.g
		println("If case let #8: ${foo}, ${bar}")
	}
	else if (bEnum is B.C) {
		val foo: Int = bEnum.d
		println("--")
	}

	if (bEnum2 is B.E && bEnum2.g == "foo") {
		val foo: Int = bEnum2.f
		println("If case let comparison #1: ${foo}")
	}

	if (bEnum2 is B.E && bEnum2.f == 0) {
		val foo: String = bEnum2.g
		println("If case let comparison #2: ${foo}")
	}

	if (bEnum2 is B.E) {
		val foo: Int = bEnum2.f
		val bar: String = bEnum2.g
		println("If case let comparison #3: ${foo}, ${bar}")
	}

	if ((true || true) && false) {
		println("--")
		if ((true || true) && false) {
			println("--")
		}
	}
	else if ((true || true) && false) {
		println("--")
	}

	if (true || true && false) {
		println("If case operator precedence")
	}

	val c0: C? = null
	val c1: C? = c0
	val c2: C? = c1?.c
	val c3: Int? = c2?.c?.x
	val c4: Int? = c2?.c?.c?.c?.x

	if (c1 != null && c2 != null && c3 != null && c4 != null) {
		// ...
	}
}

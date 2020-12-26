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
internal typealias A = Int

internal open class B {
	open class C {
	}
}

internal typealias BC = B.C
internal typealias ListInt = List<Int>

internal fun f(a: Int?) {
	a ?: return
	println(a)
}

internal interface D {
	val d: Int
}

internal fun D.f() {
	println(this.d)
}

internal open class Base {
}

internal open class Subclass: Base {
	constructor(): super() { }
}

internal open class E {
	override open fun toString(): String {
		return "abc"
	}
}

internal open class F {
	override open fun toString(): String = "abc"
}

internal open class H {
	open var description: String = "abc"
}

internal open class I {
	open class K {
		override open fun toString(): String = ""
	}
}

internal open class J {
	open class K {
		open var description: String = ""
	}
}

internal fun throwingFunction() {
}

internal data class MyError(
	val errorMessage: String
): Exception()

internal fun gryphon1() {
}

internal fun gryphon2() {
}

internal fun g() {
	try {
		println("First")
	}
	finally {
		println("Second")
	}
}

internal data class G(
	val x: Int = 0
) {
	override open fun equals(other: Any?): Boolean {
		val lhs: G = this
		val rhs: Any? = other
		if (rhs is G) {
			// User code
			return lhs.x > 0
		}
		else {
			return false
		}
	}
}

internal open class N {
	val o: Int = 0
}

internal open class M {
	val n: N = N()
}

internal open class L {
	val m: M = M()
}

fun main(args: Array<String>) {
	var i: Int = 1

	while (i <= 10) {
		if (i == 5) {
			i += 1
			continue
		}
		println(i)
		i += 1
	}

	while (true && false) {
	}

	var a: A = 0
	var bc: BC

	f(a = 10)
	println("==")
	f(a = null)
	println("==")

	val dict: Map<Int, Int> = mapOf(1 to 2)

	for (entry in dict) {
		println(entry.key)
		println(entry.value)
	}

	val maybeSubclass: Subclass? = null
	val maybeBases: List<Base?> = listOf(maybeSubclass)
	val range: IntRange = 0 until 1

	for (i in range) {
		val x: Int = i
	}

	val arrayOfInts1: List<Int> = listOf(1, 2, 3)
	val arrayOfInts2: List<Int> = listOf(1, 2, 3)
	val array: List<Int> = listOf(1, 2, 3)
	val arrayIndex: Int? = array.indexOf(1)
	val bla: Int = 1
	val array2: MutableList<Int> = mutableListOf()
	val array3: MutableList<Int> = array2 ?: mutableListOf()
	var foo: (() -> Unit)? = null
	val ik: String = I.K().toString()
	val jk: String = J.K().description

	"abc"

	try {
		"abc"
	}
	catch (_error: Exception) {
		// Do nothing
	}

	try {
		"abc"
	}
	catch (myError: Exception) {
		// Do nothing
	}

	try {
		throwingFunction()
	}
	catch (_error: Exception) {
		throw MyError(errorMessage = "")
	}

	g()

	val x: Pair<Int, Int> = Pair<Int, Int>(0, 0)

	println("${x.first}, ${x.second}")

	val y: Pair<Int, Int> = Pair<Int, Int>(0, 0)

	println("${y.first}, ${y.second}")

	val z: Pair<Pair<Int, Int>, Int> = Pair<Pair<Int, Int>, Int>(Pair<Int, Int>(0, 0), 0)

	println(z.first.first)

	val dictionary: Map<Int, Int> = mapOf(1 to 10, 2 to 20)
	val mappedDictionary: List<Int> = dictionary.map { it.key + it.value }
	val l: L? = L()

	println(l?.m?.n?.o)
}

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

fun main(args: Array<String>) {
	var i: Int = 1

	while (i <= 10) {
		println(i)
		i += 1
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

	val array: List<Int> = listOf(1, 2, 3)
	val arrayIndex: Int? = array.indexOf(1)
	val bla: Int = 1
	var foo: (() -> Unit)? = null
}

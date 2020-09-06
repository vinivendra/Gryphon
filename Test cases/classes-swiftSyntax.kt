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
internal open class Box {
	open var a: Int = 5
	open var b: String
		get() {
			return "get b"
		}
		set(newValue) {
			println("set b")
		}
	open var c: Int? = null

	open fun returnFive(): Int {
		return a
	}

	open fun returnInt(a: Int): Int {
		return a
	}
}

internal open class A {
	open class B {
	}

	val b: B = B()
}

internal open class C {
	companion object {
		fun a(): C {
			return C()
		}

		fun c(): C? {
			return C()
		}

		fun d(): C? {
			return null
		}

		fun f(): Int {
			return 1
		}
	}

	open var x: Int = 0

	open fun b(): C {
		return C()
	}

	open fun e(): Int {
		println("Hello, world!")
		return 1
	}
}

internal data class D(
	val x: Int
) {
	companion object {
		operator fun invoke(string: String?): D? {
			string ?: return null
			return when (string) {
				"A" -> D(x = 0)
				"B" -> D(x = 0)
				"C" -> D(x = 0)
				"D" -> D(x = 0)
				"E" -> D(x = 0)
				else -> null
			}
		}
	}
}

internal open class E {
	open var a: Int = 0
}

internal class F {
	open var a: Int = 0
}

internal open class MyClass {
	open var x: Int = 0

	operator open fun get(i: Int): Int {
		return x + i
	}

	operator open fun set(i: Int, newValue: Int) {
		this.x = newValue + 1
	}
}

internal open class MyOtherClass {
	operator open fun get(i: Int): Int {
		// implicit getter
		return i
	}
}

internal open class SingleExpressionMembers {
	open val one: Int
		get() = 10
	open val two: Int
		get() = 20
	open val dddddddddddddddddddddddddeeeeeeeeeee: Int
		get() = aaaaaaaaaaaaa(
			bbbbbbbbbbbbbbbb = 0,
			ccccccccccccc = 1,
			ddddddddddddddddddddddddd = 2,
			eeeeeeeeeee = 3)

	private fun aaaaaaaaaaaaa(
		bbbbbbbbbbbbbbbb: Int,
		ccccccccccccc: Int,
		ddddddddddddddddddddddddd: Int,
		eeeeeeeeeee: Int)
		: Int
		= bbbbbbbbbbbbbbbb * ccccccccccccc * ddddddddddddddddddddddddd * eeeeeeeeeee
}

internal open class Superclass {
	open var x: Int = 0

	constructor(x: Int) {
		this.x = x
	}
}

internal open class Subclass: Superclass {
	constructor(y: Int): super(x = y + 1) {
	}
}

fun main(args: Array<String>) {
	val box1: Box = Box()

	println(box1.a)
	println(box1.returnFive())
	println(box1.returnInt(a = 10))
	println(box1.b)

	box1.b = "whatever"

	println(box1.c)
	println(C.a().x)
	println(C().b().x)

	var a: C? = C.c()
	val ac: C? = a

	if (ac != null) {
		println(ac.x)
	}

	a = C.d()

	val ad: C? = a

	if (ad != null) {
		println(ad.x)
	}

	println(C().e())
	println(C.f())
	println(D(x = 10))
	println(D(string = "not supported"))
	println(D(string = "A")!!)

	val myClass: MyClass = MyClass()

	println(myClass[1])
	println(myClass[2])
	println(myClass[3])

	myClass[1] = 10

	println(myClass[1])
	println(myClass[2])
	println(myClass[3])

	val singleExpressionMembers: SingleExpressionMembers = SingleExpressionMembers()

	println(singleExpressionMembers.one)
	println(singleExpressionMembers.two)
	println(singleExpressionMembers.dddddddddddddddddddddddddeeeeeeeeeee)
}

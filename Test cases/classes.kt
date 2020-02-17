//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
internal open class Box {
	var a: Int = 5
	var b: String
		get() {
			return "get b"
		}
		set(newValue) {
			println("set b")
		}
	var c: Int? = null

	fun returnFive(): Int {
		return a
	}

	fun returnInt(a: Int): Int {
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

	var x: Int = 0

	fun b(): C {
		return C()
	}

	fun e(): Int {
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
}

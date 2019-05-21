//
// Copyright 2018 Vinícius Jorge Vendramini
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
open class A {
	companion object {
		internal fun a(): A {
			return A()
		}

		internal fun c(): A? {
			return A()
		}

		internal fun d(): A? {
			return null
		}

		internal fun f(): Int {
			return 1
		}
	}

	var x: Int = 0

	internal fun b(): A {
		return A()
	}

	internal fun e(): Int {
		println("Hello, world!")
		return 1
	}
}

data class B(
	val x: Int
) {
	companion object {
		operator fun invoke(string: String?): B? {
			string ?: return null
			return when (string) {
				"A" -> B(x = 0)
				"B" -> B(x = 0)
				"C" -> B(x = 0)
				"D" -> B(x = 0)
				"E" -> B(x = 0)
				else -> null
			}
		}
	}
}

fun main(args: Array<String>) {
	println(A.a().x)
	println(A().b().x)

	var a: A? = A.c()
	val ac: A? = a

	if (ac != null) {
		println(ac.x)
	}

	a = A.d()

	val ad: A? = a

	if (ad != null) {
		println(ad.x)
	}

	println(A().e())
	println(A.f())
	println(B(x = 10))
	println(B(string = "not supported"))
	println(B(string = "A")!!)
}

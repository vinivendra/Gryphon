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
open class Box {
	var a: Int = 5
	var b: String
		get() {
			return "get b"
		}
		set(newValue) {
			println("set b")
		}
	var c: Int? = null

	internal fun returnFive(): Int {
		return a
	}

	internal fun returnInt(a: Int): Int {
		return a
	}
}

open class A {
	open class B {
	}

	val b: B = B()
}

fun main(args: Array<String>) {
	val box1: Box = Box()

	println(box1.a)
	println(box1.returnFive())
	println(box1.returnInt(a = 10))
	println(box1.b)

	box1.b = "whatever"

	println(box1.c)
}

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
}

internal fun f() {
	val number: Int = 0
	val name: String = when (number) {
		0 -> "Zero"
		else -> "More"
	}
}

fun main(args: Array<String>) {
	printNumberName(0)
	printNumberName(1)
	printNumberName(2)
	printNumberName(3)
	printNumberName(4)
	printNumberName(7)
	printNumberName(10)

	println(getNumberName(0))
	println(getNumberName(1))
	println(getNumberName(2))
	println(getNumberName(3))
	println(getNumberName(4))

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
	}

	val z: Int = 0

	when (z) {
		0 -> {
		}
		1 -> println(1)
		else -> println(2)
	}
}

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
fun f(a: Int) {
	println(a)
}

fun main(args: Array<String>) {
	println(0)
	print(0)
	println(0)
	println(Math.sqrt(9.0))
	println("".isEmpty())
	println("a".isEmpty())
	println("".length)
	println("a".length)
	println("0".toDouble())
	println("1".toDouble())
	println("abcde".dropLast(1))
	println("abcde".substring(0, 4))

	var array: MutableList<Int> = mutableListOf(1, 2, 3)

	println(array)
	array.add(4)
	println(array)

	val emptyArray: MutableList<Int> = mutableListOf()

	println(emptyArray.isEmpty())
	println(array.isEmpty())

	val stringArray: MutableList<String> = mutableListOf("1", "2", "3")

	println(stringArray.joinToString(separator = " => "))
	println(array.size)
	println(stringArray.size)
	println(array.lastOrNull())
	println(array.dropLast(1))

	val dictionary: MutableMap<Int, Int> = mutableMapOf(10 to 1, 20 to 2, 30 to 3)
	val reduceResult: Int = dictionary.entries.fold(initial = 0, operation = { acc, keyValue -> acc + keyValue.value })

	println(reduceResult)
	println(Int.MAX_VALUE)
	println(Int.MIN_VALUE)
	println(Math.min(0, 1))
	println(Math.min(15, -30))
	println(0..3)
	println(-1 until 3)
	println((1.0).rangeTo(3.0))
	println(Int.MIN_VALUE until 0)
	f(a = 10)
}

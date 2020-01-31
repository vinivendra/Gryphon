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
	val string: String = "abcde"
	val bIndex: Int = 1
	val cIndex: Int = 2
	val dIndex: Int = 3
	var variableIndex: Int = cIndex
	val substring: String = "abcd"
	val range: IntRange = IntRange(0, string.length)
	var variableString: String = "abcde"
	val character: Char = 'i'

	println(0)
	print(0)
	println(0)
	println(Math.sqrt(9.0))
	println(0.toString())
	println("bla".toString())
	println("".isEmpty())
	println("a".isEmpty())
	println("".length)
	println("a".length)
	println("abc".firstOrNull()!!)
	println("".firstOrNull())
	println("abc".lastOrNull()!!)
	println("".lastOrNull())
	println("0".toDouble())
	println("1".toDouble())
	println("0".toFloat())
	println("1".toFloat())
	println("0".toULong())
	println("1".toULong())
	println("0".toLong())
	println("1".toLong())
	println("0".toIntOrNull())
	println("1".toIntOrNull())
	println("abcde".dropLast(1))
	println("abcde".dropLast(2))
	println("abcde".drop(1))
	println("abcde".drop(2))

	for (index in string.indices) {
		println(string[index])
	}

	println("abcde".substring(0, 4))
	println("abcde".substring(0, cIndex))
	println("abcde".substring(cIndex))
	println("abcde".substring(0, cIndex))
	println("abcde".substring(0, cIndex + 1))
	println("abcde".substring(bIndex, dIndex))
	println("abcde".substring(bIndex, dIndex + 1))
	println(substring)
	println(string.substring(0, string.length))
	println(string[0])
	variableIndex -= 1
	println(string[variableIndex])
	println(string[cIndex + 1])
	println(string[cIndex - 1])
	println(string[cIndex + 2])
	println(substring[bIndex + 1])
	println("aaBaBAa".replace("a", "A"))
	println(string.takeWhile { it != 'c' })
	println(string.startsWith("abc"))
	println(string.startsWith("d"))
	println(string.endsWith("cde"))
	println(string.endsWith("a"))
	println(range.start == 0)
	println(range.start == string.length)
	println(range.endInclusive == 0)
	println(range.endInclusive == string.length)

	val newRange: IntRange = IntRange(0, string.length)

	println(newRange.start == 0)
	println(newRange.start == string.length)
	println(newRange.endInclusive == 0)
	println(newRange.endInclusive == string.length)
	variableString += "fgh"
	println(variableString)
	variableString += character
	println(variableString)
	println(string.capitalize())
	println(string.toUpperCase())

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

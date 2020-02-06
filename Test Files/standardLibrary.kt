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
typealias PrintContents = Any?

internal fun printTest(contents: PrintContents, testName: String) {
	val firstColumnSize: Int = 40
	val contentsString: String = "${contents}"

	print(contentsString)

	if (contentsString.length < firstColumnSize) {
		for (_0 in contentsString.length until firstColumnSize) {
			print(" ")
		}
	}

	println("(${testName})")
}

fun g(a: Int) {
	printTest(a, "User template")
}

fun main(args: Array<String>) {
	println("Hello, world!")
	println(42)

	val message: String = "A message in a variable."

	println(message)

	val number: Int = 13

	println(number)
	println("Here's a bool literal: ${true}.\nAnd here's a number: ${17}.")
	println("The stored message is: ${message}\nAnd the stored number is: ${number}.")
	print(0)
	println(" (Print)")

	printTest(Math.sqrt(9.0), "Sqrt")

	val string: String = "abcde"
	val bIndex: Int = 1
	val cIndex: Int = 2
	val dIndex: Int = 3
	var variableIndex: Int = cIndex
	val substring: String = "abcd"
	val range: IntRange = IntRange(0, string.length)
	var variableString: String = "abcde"
	val character: Char = 'i'

	printTest(0.toString(), "String(_anyType)")
	printTest("bla".toString(), "String description")
	printTest("".isEmpty(), "String isEmpty")
	printTest("a".isEmpty(), "String isEmpty")
	printTest("".length, "String count")
	printTest("a".length, "String count")
	printTest("abc".firstOrNull()!!, "String first")
	printTest("".firstOrNull(), "String first")
	printTest("abc".lastOrNull()!!, "String last")
	printTest("".lastOrNull(), "String last")
	printTest("0".toDouble(), "String double")
	printTest("1".toDouble(), "String double")
	printTest("0".toFloat(), "String float")
	printTest("1".toFloat(), "String float")
	printTest("0".toULong(), "String uint64")
	printTest("1".toULong(), "String uint64")
	printTest("0".toLong(), "String int64")
	printTest("1".toLong(), "String int64")
	printTest("0".toIntOrNull(), "String int")
	printTest("1".toIntOrNull(), "String int")
	printTest("abcde".dropLast(1), "String dropLast()")
	printTest("abcde".dropLast(2), "String dorpLast(int)")
	printTest("abcde".drop(1), "String dropFirst")
	printTest("abcde".drop(2), "String dropFirst(int)")

	for (index in string.indices) {
		printTest(string[index], "String indices")
	}

	printTest("abcde".substring(0, 4), "String prefix")
	printTest("abcde".substring(0, cIndex), "String prefix(upTo:)")
	printTest("abcde".substring(cIndex), "String index...")
	printTest("abcde".substring(0, cIndex), "String ..<index")
	printTest("abcde".substring(0, cIndex + 1), "String ...index")
	printTest("abcde".substring(bIndex, dIndex), "String index..<index")
	printTest("abcde".substring(bIndex, dIndex + 1), "String index...index")
	printTest(substring, "String String(substring)")
	printTest(string.substring(0, string.length), "String endIndex")
	printTest(string[0], "String startIndex")

	variableIndex -= 1

	printTest(string[variableIndex], "String formIndex(brefore:)")
	printTest(string[cIndex + 1], "String index after")
	printTest(string[cIndex - 1], "String index before")
	printTest(string[cIndex + 2], "String index offset by")
	printTest(substring[bIndex + 1], "String substring index offset by")
	printTest("aaBaBAa".replace("a", "A"), "String replacing occurrences")
	printTest(string.takeWhile { it != 'c' }, "String prefix while")
	printTest(string.startsWith("abc"), "String hasPrefix")
	printTest(string.startsWith("d"), "String hasPrefix")
	printTest(string.endsWith("cde"), "String hasSuffix")
	printTest(string.endsWith("a"), "String hasSuffix")
	printTest(range.start == 0, "String range lowerBound")
	printTest(range.start == string.length, "String range lowerBound")
	printTest(range.endInclusive == 0, "String range upperBound")
	printTest(range.endInclusive == string.length, "String range upperBound")

	val newRange: IntRange = IntRange(0, string.length)

	printTest(newRange.start == 0, "String range uncheckedBounds")
	printTest(newRange.start == string.length, "String range uncheckedBounds")
	printTest(newRange.endInclusive == 0, "String range uncheckedBounds")
	printTest(newRange.endInclusive == string.length, "String range uncheckedBounds")

	variableString += "fgh"

	printTest(variableString, "String append")

	variableString += character

	printTest(variableString, "String append character")
	printTest(string.capitalize(), "String capitalized")
	printTest(string.toUpperCase(), "String uppercased")
	printTest(character.toUpperCase(), "Character uppercased")

	val array2: List<Int> = listOf(2, 1)
	val array4: List<Int> = listOf(2, 1)
	val emptyArray: List<Int> = listOf()
	val stringArray: List<String> = listOf("1", "2", "3")

	val array: MutableList<Int> = mutableListOf(1, 2, 3)
	val array3: MutableList<Int> = mutableListOf(1)
	val arrayOfOptionals: MutableList<Int?> = mutableListOf(1)

	printTest(array, "Array append")

	array.add(4)

	printTest(array, "Array append")

	array.add(0, 0)

	printTest(array, "Array insert")

	array.add(5, 5)

	printTest(array, "Array insert")

	array.add(3, 10)

	printTest(array, "Array insert")

	arrayOfOptionals.add(null)

	printTest(arrayOfOptionals, "Array append nil")

	array3.addAll(array2)

	printTest(array3, "Array append(contentsOf:) constant")

	array3.addAll(array4)

	printTest(array3, "Array append(contentsOf:) variable")
	printTest(emptyArray.isEmpty(), "Array isEmpty")
	printTest(array.isEmpty(), "Array isEmpty")
	printTest(stringArray.joinToString(separator = " => "), "Array joined separator")
	printTest(stringArray.joinToString(separator = ""), "Array joined")
	printTest(array.size, "Array count")
	printTest(stringArray.size, "Array count")

	for (index in array.indices) {
		printTest(array[index], "Array indices")
	}

	printTest(array[0], "Array startIndex")
	printTest(array.size == array.size, "Array endIndex")
	printTest(2 + 1, "Array index after")
	printTest(2 - 1, "Array index before")
	printTest(array.firstOrNull(), "Array first")
	printTest(emptyArray.firstOrNull(), "Array first")
	printTest(array.find { it > 3 }, "Array first where")
	printTest(array.findLast { it > 3 }, "Array last where")
	printTest(array.lastOrNull(), "Array last")

	array.removeAt(0)

	printTest(array, "Array remove first")
	printTest(array.drop(1), "Array drop first")
	printTest(array.dropLast(1), "Array drop last")
	printTest(array.map { it + 1 }.toMutableList(), "Array map")
	printTest(array.flatMap { listOf(it + 1, it + 2) }.toMutableList(), "Array flat map")
	printTest(
		array.map { if (it == 10) { it } else { null } }.filterNotNull().toMutableList(),
		"Array compact map")
	printTest(array.filter { it < 10 }.toMutableList(), "Array filter")
	printTest(array.fold(1) { acc, el -> acc * el }, "Array reduce")

	for ((element1, element2) in array.zip(array2)) {
		printTest(element1, "Array zip")
		printTest(element2, "Array zip")
	}

	printTest(array.indexOfFirst { it > 2 }, "Array firstIndex")
	printTest((array.find { it > 2 } != null), "Array contains where")
	printTest((array.find { it > 2000 } != null), "Array contains where")
	printTest(array.sorted(), "Array sorted")
	printTest(array.contains(10), "Array contains")
	printTest(array.contains(10000), "Array contains")
	printTest(array.indexOf(10), "Array firstIndex of")

	val dictionary: Map<Int, Int> = mapOf(1 to 1, 2 to 2)
	val emptyDictionary: Map<Int, Int> = mapOf()

	printTest(dictionary.size, "Dictionary count")
	printTest(dictionary.isEmpty(), "Dictionary isEmpty")
	printTest(emptyDictionary.isEmpty(), "Dictionary isEmpty")

	val mappedDictionary: List<Int> = dictionary.map { it.value + it.key }

	printTest(mappedDictionary[0], "Dictionary map")
	printTest(mappedDictionary[1], "Dictionary map")
	printTest(Int.MAX_VALUE, "Int max")
	printTest(Int.MIN_VALUE, "Int min")
	printTest(Math.min(0, 1), "Int min(a, b)")
	printTest(Math.min(15, -30), "Int min(a, b)")
	printTest(0..3, "Int ...")
	printTest(-1 until 3, "Int ..<")
	printTest((1.0).rangeTo(3.0), "Double ...")
	printTest(Int.MIN_VALUE until 0, "Recursive matches")

	g(a = 10)
}

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
import kotlin.system.*
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

internal open class A {
	val string: String = ""
}

internal open class B {
	open var description: String = ""
}

internal open class C {
	override open fun toString(): String = ""
}

fun g(a: Int) {
	printTest(contents = a, testName = "User template")
}

enum class G {
	I, J;

	enum class H {
		K, L;
	}
}

internal open class D {
	open class E {
		override open fun toString(): String = ""
	}
}

internal val String.bla: Int
	get() {
		return 0
	}

internal open class M {
}

internal val M.bla: Int
	get() {
		return 10
	}
internal val M.foo: Int
	get() {
		return 0
	}

internal enum class N {
	O;
}

internal val N.bla: Int
	get() {
		return 10
	}
internal val N.foo: Int
	get() {
		return 0
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
	printTest(contents = Math.sqrt(9.0), testName = "Sqrt")

	val int: Int = 1
	val float: Float = 0.1f
	val float1: Float = 0.5f
	val float2: Float = 0.9f
	val double: Double = 0.1
	val double1: Double = 0.5
	val double2: Double = 0.9

	printTest(contents = int.toDouble(), testName = "Int to Double")
	printTest(contents = int.toFloat(), testName = "Int to Float")
	printTest(contents = float.toDouble(), testName = "Float to Double")
	printTest(contents = float.toInt(), testName = "Float (0.1) to Int")
	printTest(contents = float1.toInt(), testName = "Float (0.5) to Int")
	printTest(contents = float2.toInt(), testName = "Float (0.9) to Int")
	printTest(contents = double.toFloat(), testName = "Double to Float")
	printTest(contents = double.toInt(), testName = "Double (0.1) to Int")
	printTest(contents = double1.toInt(), testName = "Double (0.5) to Int")
	printTest(contents = double2.toInt(), testName = "Double (0.9) to Int")

	val string: String = "abcde"
	val bIndex: Int = 1
	val cIndex: Int = 2
	val dIndex: Int = 3
	var variableIndex: Int = cIndex
	val substring: String = "abcd"
	val range: IntRange = IntRange(0, string.length)
	var variableString: String = "abcde"
	val character: Char = 'i'

	printTest(contents = 0.toString(), testName = "String(_anyType)")
	printTest(contents = "bla".toString(), testName = "String description")
	printTest(contents = "".isEmpty(), testName = "String isEmpty")
	printTest(contents = "a".isEmpty(), testName = "String isEmpty")
	printTest(contents = "".length, testName = "String count")
	printTest(contents = "a".length, testName = "String count")
	printTest(contents = "abc".firstOrNull()!!, testName = "String first")
	printTest(contents = "".firstOrNull(), testName = "String first")
	printTest(contents = "abc".lastOrNull()!!, testName = "String last")
	printTest(contents = "".lastOrNull(), testName = "String last")
	printTest(contents = "0".toDouble(), testName = "String double")
	printTest(contents = "1".toDouble(), testName = "String double")
	printTest(contents = "0".toFloat(), testName = "String float")
	printTest(contents = "1".toFloat(), testName = "String float")
	printTest(contents = "0".toULong(), testName = "String uint64")
	printTest(contents = "1".toULong(), testName = "String uint64")
	printTest(contents = "0".toLong(), testName = "String int64")
	printTest(contents = "1".toLong(), testName = "String int64")
	printTest(contents = "0".toIntOrNull(), testName = "String int")
	printTest(contents = "1".toIntOrNull(), testName = "String int")
	printTest(contents = "abcde".dropLast(1), testName = "String dropLast()")
	printTest(contents = "abcde".dropLast(2), testName = "String dorpLast(int)")
	printTest(contents = "abcde".drop(1), testName = "String dropFirst")
	printTest(contents = "abcde".drop(2), testName = "String dropFirst(int)")

	for (index in string.indices) {
		printTest(contents = string[index], testName = "String indices")
	}

	printTest(contents = "abcde".substring(0, 4), testName = "String prefix")
	printTest(contents = "abcde".substring(0, cIndex), testName = "String prefix(upTo:)")
	printTest(contents = "abcde".substring(cIndex), testName = "String index...")
	printTest(contents = "abcde".substring(0, cIndex), testName = "String ..<index")
	printTest(contents = "abcde".substring(0, cIndex + 1), testName = "String ...index")
	printTest(contents = "abcde".substring(bIndex, dIndex), testName = "String index..<index")
	printTest(contents = "abcde".substring(bIndex, dIndex + 1), testName = "String index...index")
	printTest(contents = substring, testName = "String String(substring)")
	printTest(contents = string.substring(0, string.length), testName = "String endIndex")
	printTest(contents = string[0], testName = "String startIndex")

	variableIndex -= 1

	printTest(contents = string[variableIndex], testName = "String formIndex(brefore:)")
	printTest(contents = string[cIndex + 1], testName = "String index after")
	printTest(contents = string[cIndex - 1], testName = "String index before")
	printTest(contents = string[cIndex + 2], testName = "String index offset by")
	printTest(contents = substring[bIndex + 1], testName = "String substring index offset by")
	printTest(contents = "aaBaBAa".replace("a", "A"), testName = "String replacing occurrences")
	printTest(contents = string.takeWhile { it != 'c' }, testName = "String prefix while")
	printTest(contents = string.startsWith("abc"), testName = "String hasPrefix")
	printTest(contents = string.startsWith("d"), testName = "String hasPrefix")
	printTest(contents = string.endsWith("cde"), testName = "String hasSuffix")
	printTest(contents = string.endsWith("a"), testName = "String hasSuffix")
	printTest(contents = range.start == 0, testName = "String range lowerBound")
	printTest(contents = range.start == string.length, testName = "String range lowerBound")
	printTest(contents = range.endInclusive == 0, testName = "String range upperBound")
	printTest(contents = range.endInclusive == string.length, testName = "String range upperBound")

	val newRange: IntRange = IntRange(0, string.length)

	printTest(contents = newRange.start == 0, testName = "String range uncheckedBounds")
	printTest(contents = newRange.start == string.length, testName = "String range uncheckedBounds")
	printTest(contents = newRange.endInclusive == 0, testName = "String range uncheckedBounds")
	printTest(
		contents = newRange.endInclusive == string.length,
		testName = "String range uncheckedBounds")

	variableString += "fgh"

	printTest(contents = variableString, testName = "String append")

	variableString += character

	printTest(contents = variableString, testName = "String append character")
	printTest(contents = string.capitalize(), testName = "String capitalized")
	printTest(contents = string.toUpperCase(), testName = "String uppercased")
	printTest(contents = character.toUpperCase(), testName = "Character uppercased")

	val array2: List<Int> = listOf(2, 1)
	val array4: List<Int> = listOf(2, 1)
	val emptyArray: List<Int> = listOf()
	val stringArray: List<String> = listOf("1", "2", "3")

	val array: MutableList<Int> = mutableListOf(1, 2, 3)
	val array3: MutableList<Int> = mutableListOf(1)
	val arrayOfOptionals: MutableList<Int?> = mutableListOf(1)

	printTest(contents = array, testName = "Array append")
	array.add(4)
	printTest(contents = array, testName = "Array append")
	array.add(0, 0)
	printTest(contents = array, testName = "Array insert")
	array.add(5, 5)
	printTest(contents = array, testName = "Array insert")
	array.add(3, 10)
	printTest(contents = array, testName = "Array insert")
	arrayOfOptionals.add(null)
	printTest(contents = arrayOfOptionals, testName = "Array append nil")
	array3.addAll(array2)
	printTest(contents = array3, testName = "Array append(contentsOf:) constant")
	array3.addAll(array4)
	printTest(contents = array3, testName = "Array append(contentsOf:) variable")
	printTest(contents = emptyArray.isEmpty(), testName = "Array isEmpty")
	printTest(contents = array.isEmpty(), testName = "Array isEmpty")
	printTest(
		contents = stringArray.joinToString(separator = " => "),
		testName = "Array joined separator")
	printTest(contents = stringArray.joinToString(separator = ""), testName = "Array joined")
	printTest(contents = array.size, testName = "Array count")
	printTest(contents = stringArray.size, testName = "Array count")

	for (index in array.indices) {
		printTest(contents = array[index], testName = "Array indices")
	}

	printTest(contents = array[0], testName = "Array startIndex")
	printTest(contents = array.size == array.size, testName = "Array endIndex")
	printTest(contents = 2 + 1, testName = "Array index after")
	printTest(contents = 2 - 1, testName = "Array index before")
	printTest(contents = array.firstOrNull(), testName = "Array first")
	printTest(contents = emptyArray.firstOrNull(), testName = "Array first")
	printTest(contents = array.find { it == 1 }, testName = "Array first where")
	printTest(contents = array.find { it > 3 }, testName = "Array first where")
	printTest(contents = array.findLast { it > 3 }, testName = "Array last where")
	printTest(contents = array.lastOrNull(), testName = "Array last")
	array.removeAt(0)
	printTest(contents = array, testName = "Array remove first")
	printTest(contents = array.drop(1), testName = "Array drop first")
	printTest(contents = array.dropLast(1), testName = "Array drop last")
	printTest(contents = array.map { it + 1 }, testName = "Array map")
	printTest(contents = array.flatMap { listOf(it + 1, it + 2) }, testName = "Array flat map")
	printTest(
		contents = array.map { if (it == 10) { it } else { null } }.filterNotNull(),
		testName = "Array compact map")
	printTest(contents = array.filter { it < 10 }, testName = "Array filter")
	printTest(contents = array.fold(1) { acc, el -> acc * el }, testName = "Array reduce")

	for ((element1, element2) in array.zip(array2)) {
		printTest(contents = element1, testName = "Array zip")
		printTest(contents = element2, testName = "Array zip")
	}

	printTest(contents = array.indexOfFirst { it > 2 }, testName = "Array firstIndex")
	printTest(contents = (array.find { it > 2 } != null), testName = "Array contains where")
	printTest(contents = (array.find { it > 2000 } != null), testName = "Array contains where")
	printTest(contents = array.sorted(), testName = "Array sorted")
	printTest(contents = array.contains(10), testName = "Array contains")
	printTest(contents = array.contains(10000), testName = "Array contains")
	printTest(contents = array.indexOf(10), testName = "Array firstIndex of")

	array.clear()

	printTest(contents = array, testName = "Array remove all")

	val dictionary: Map<Int, Int> = mapOf(1 to 1, 2 to 2)
	val emptyDictionary: Map<Int, Int> = mapOf()

	printTest(contents = dictionary.size, testName = "Dictionary count")
	printTest(contents = dictionary.isEmpty(), testName = "Dictionary isEmpty")
	printTest(contents = emptyDictionary.isEmpty(), testName = "Dictionary isEmpty")

	val mappedDictionary: List<Int> = dictionary.map { it.value + it.key }

	printTest(contents = mappedDictionary[0], testName = "Dictionary map")
	printTest(contents = mappedDictionary[1], testName = "Dictionary map")
	printTest(contents = Int.MAX_VALUE, testName = "Int max")
	printTest(contents = Int.MIN_VALUE, testName = "Int min")
	printTest(contents = Math.min(0, 1), testName = "Int min(a, b)")
	printTest(contents = Math.min(15, -30), testName = "Int min(a, b)")
	printTest(contents = 0..3, testName = "Int ...")
	printTest(contents = -1 until 3, testName = "Int ..<")
	printTest(contents = (1.0).rangeTo(3.0), testName = "Double ...")
	printTest(contents = Int.MIN_VALUE until 0, testName = "Recursive matches")

	g(a = 10)

	val maybeA: A? = null
	val a: A? = maybeA
	val b: Char? = a?.string?.firstOrNull()

	if (a != null && b != null) {
	}

	println(
		listOf(1, 2, 3).map { a ->
					if (a > 1) {
						return@map 1
					}
					else {
						return@map 2
					}
				})
	println(
		listOf(1, 2, 3).map { a ->
					if (a > 1) {
						return@map listOf(1, 2, 3).filter { b ->
								if (b > 1) {
									return@filter true
								}
								else {
									return@filter false
								}
							}
					}
					else {
						return@map listOf(2)
					}
				})

	val description1: String = B().description
	val description2: String = C().toString()
	val description: String = ""

	if (false) {
		println("Fatal error: ${"Never reached"}"); exitProcess(-1)
	}

	val w: G = G.I
	val x: G = G.J
	val y: G.H = G.H.K
	val z: G.H = G.H.L
}

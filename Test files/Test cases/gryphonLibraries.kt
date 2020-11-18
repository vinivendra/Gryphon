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
import java.lang.ClassCastException

fun String.suffix(startIndex: Int): String {
    return this.substring(startIndex, this.length)
}

fun <T> MutableList<T>.removeLast() {
    this.removeAt(this.size - 1)
}

fun String.indexOrNull(character: Char): Int? {
    val result = this.indexOf(character)
    if (result == -1) {
        return null
    }
    else {
        return result
    }
}

@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified T> List<*>.castOrNull(): List<T>? {
    if (this.all { it is T }) {
        return this as List<T>
    }
    else {
        return null
    }
}

@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified T> List<*>.castMutableOrNull(): MutableList<T>? {
    if (this.all { it is T }) {
        return (this as List<T>).toMutableList()
    }
    else {
        return null
    }
}

@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified K, reified V> Map<*, *>.castOrNull()
    : Map<K, V>?
{
    if (this.all { it.key is K && it.value is V }) {
        return this as Map<K, V>
    }
    else {
        return null
    }
}

@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified K, reified V> Map<*, *>.castMutableOrNull()
    : MutableMap<K, V>?
{
    if (this.all { it.key is K && it.value is V }) {
        return (this as Map<K, V>).toMutableMap()
    }
    else {
        return null
    }
}


@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified T> List<*>.cast(): List<T> {
    if (this.all { it is T }) {
        return this as List<T>
    }
    else {
        throw ClassCastException()
    }
}

@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified T> List<*>.castMutable(): MutableList<T> {
    if (this.all { it is T }) {
        return (this as List<T>).toMutableList()
    }
    else {
        throw ClassCastException()
    }
}

@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified K, reified V> Map<*, *>.cast()
    : Map<K, V>
{
    if (this.all { it.key is K && it.value is V }) {
        return this as Map<K, V>
    }
    else {
        throw ClassCastException()
    }
}

@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified K, reified V> Map<*, *>.castMutable()
    : MutableMap<K, V>
{
    if (this.all { it.key is K && it.value is V }) {
        return (this as Map<K, V>).toMutableMap()
    }
    else {
        throw ClassCastException()
    }
}

fun <Element> List<Element>.sorted(
    isAscending: (Element, Element) -> Boolean)
    : MutableList<Element>
{
    val copyList = this.toMutableList()
    copyList.quicksort(0, this.size - 1, isAscending)
    return copyList
}

fun <Element> MutableList<Element>.quicksort(
    left: Int,
    right: Int,
    isAscending: (Element, Element) -> Boolean)
{
    if (left < right) {
        val pivot = this.partition(left, right, isAscending)
        this.quicksort(left, pivot - 1, isAscending)
        this.quicksort(pivot + 1, right, isAscending)
    }
}

fun <Element> MutableList<Element>.partition(
    left: Int,
    right: Int,
    isAscending: (Element, Element) -> Boolean)
    : Int
{
    val pivot = this[right]

    var i = left - 1

    var j = left
    while (j <= right - 1) {
        if (isAscending(this[j], pivot)) {
            i += 1

            val aux = this[i]
            this[i] = this[j]
            this[j] = aux
        }

        j += 1
    }

    val aux = this[i + 1]
    this[i + 1] = this[right]
    this[right] = aux

    return i + 1
}

fun main(args: Array<String>) {
	val strings: List<String> = listOf("abc", "def")
	val anys: List<Any>? = strings.castOrNull<Any>()

	println(anys)

	val mutableAnys: MutableList<Any>? = strings.castMutableOrNull<Any>()

	println(mutableAnys)

	val forcedAnys: List<Any> = strings.cast<Any>()

	println(forcedAnys)

	val mutableForcedAnys: MutableList<Any> = strings.castMutable<Any>()

	println(mutableForcedAnys)

	val failedCast1: List<Int>? = strings.castOrNull<Int>()

	println(failedCast1)

	val anys2: List<Any> = listOf("", 0)
	val failedCast2: List<String>? = anys2.castOrNull<String>()

	println(failedCast2)

	val nativeArray: List<Int> = listOf(1, 2, 3)
	val nativeMap: Map<Int, Int> = mapOf(1 to 2)
	val list1: List<Int> = nativeArray.toMutableList()
	val list2: MutableList<Int> = nativeArray.toMutableList()
	val map1: Map<Int, Int> = nativeMap.toMutableMap()
	val map2: MutableMap<Int, Int> = nativeMap.toMutableMap()
}

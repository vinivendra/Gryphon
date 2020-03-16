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

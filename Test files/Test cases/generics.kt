//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//
internal data class Box<T>(
	val x: T
)

internal open class Box2<T> {
	val x: T? = null
}

internal fun <T> f1(box: Box<T>) {
	println(box.x)
}

internal fun <T> f2(box: Box<T>): T {
	return box.x
}

internal fun <T> Box<T>.f3() {
}

internal fun <U, T> Box<T>.f4(box: Box<U>) {
	println(this.x)
	println(box.x)
}

internal val <T> Box<T>.a: Int
	get() {
		return 0
	}

internal fun <Key> f(): Map<Key, String> {
	return mapOf()
}

fun main(args: Array<String>) {
	val box: Box<Int> = Box(0)
	val box1: Box<Int> = Box(0)

	f1(Box(1))
	println(f2(Box(2)))
	Box(3).f4(Box(4))
}

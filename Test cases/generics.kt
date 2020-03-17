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
internal data class Box<T>(
	val x: T
) {
}

internal fun <T> f1(box: Box<T>) {
	println(box.x)
}

internal fun <T> f2(box: Box<T>): T {
	return box.x
}

internal fun <T, U> Box<T>.f3(box: Box<U>) {
	println(this.x)
	println(box.x)
}

fun main(args: Array<String>) {
	val box: Box<Int> = Box(x = 0)

	f1(box = Box(x = 1))

	println(f2(box = Box(x = 2)))

	Box(x = 3).f3(box = Box(x = 4))
}

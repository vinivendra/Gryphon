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

fun main(args: Array<String>) {
	val array1: MutableList<Int> = mutableListOf(1, 2, 3)
	val array2: MutableList<Int> = array1

	array1[0] = 10

	println(array1)
	println(array2)
	println(array2[0])

	for (i in array1) {
		println(i)
	}

	for (j in array2) {
		println(j)
	}

	for (i in array1) {
		for (j in array2) {
			println("${i}, ${j}")
		}
	}

	val fixedArray1: List<Int> = listOf(1, 2, 3)

	println(fixedArray1[2] == 3)

	val fixedArray2: List<Int> = listOf()

	println(fixedArray2.size == 0)

	val fixedArray3: List<Any>? = fixedArray1 as? List<Any>
	val fixedArray4: List<Int>? = fixedArray3!! as? List<Int>

	println(fixedArray4!![2] == 3)

	for (item in fixedArray1) {
		println(item)
	}

	println(fixedArray1.isEmpty())
	println(fixedArray2.isEmpty())
	println(fixedArray1.firstOrNull()!! == 1)
	println(fixedArray1.lastOrNull()!! == 3)
	println(fixedArray2.firstOrNull() == null)
	println(fixedArray2.lastOrNull() == null)

	val fixedArray5: List<Int> = fixedArray1.filter { it > 2 }.toMutableList()

	println(fixedArray5.size == 1)
	println(fixedArray5[0] == 3)

	val fixedArray6: List<Int> = fixedArray1.map { it + 1 }.toMutableList()

	println(fixedArray6.size == 3)
	println(fixedArray6[2] == 4)

	val fixedArray7: List<Int> = fixedArray1.map { if (it > 2) { it } else { null } }.filterNotNull().toMutableList()

	println(fixedArray7.size == 1)
	println(fixedArray7[0] == 3)

	val fixedArray8: List<Int> = fixedArray1.flatMap { a -> listOf(a, a + 1) }.toMutableList()

	println(fixedArray8.size == 6)
	println(fixedArray8[0] == 1)
	println(fixedArray8[5] == 4)

	val fixedArray9: List<Int> = listOf(3, 2, 1)
	val fixedArray10: List<Int> = fixedArray9.sorted()

	println(fixedArray10[0] == 1)
}

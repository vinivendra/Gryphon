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
	val mutableList1: MutableList<Int> = mutableListOf(1, 2, 3)
	val mutableList2: MutableList<Int> = mutableList1

	mutableList1[0] = 10

	println(mutableList1)
	println(mutableList2)
	println(mutableList2[0])

	for (i in mutableList1) {
		println(i)
	}

	for (j in mutableList2) {
		println(j)
	}

	for (i in mutableList1) {
		for (j in mutableList2) {
			println("${i}, ${j}")
		}
	}

	val list1: List<Int> = listOf(1, 2, 3)

	println(list1[2] == 3)

	val list2: List<Int> = listOf()

	println(list2.size == 0)

	val list3: List<Any>? = list1 as? List<Any>
	val list4: List<Int>? = list3!! as? List<Int>

	println(list4!![2] == 3)

	for (item in list1) {
		println(item)
	}

	println(list1.isEmpty())
	println(list2.isEmpty())
	println(list1.firstOrNull()!! == 1)
	println(list1.lastOrNull()!! == 3)
	println(list2.firstOrNull() == null)
	println(list2.lastOrNull() == null)

	val list5: List<Int> = list1.filter { it > 2 }.toMutableList()

	println(list5.size == 1)
	println(list5[0] == 3)

	val list6: List<Int> = list1.map { it + 1 }.toMutableList()

	println(list6.size == 3)
	println(list6[2] == 4)

	val list7: List<Int> = list1.map { if (it > 2) { it } else { null } }.filterNotNull().toMutableList()

	println(list7.size == 1)
	println(list7[0] == 3)

	val list8: List<Int> = list1.flatMap { a -> listOf(a, a + 1) }.toMutableList()

	println(list8.size == 6)
	println(list8[0] == 1)
	println(list8[5] == 4)

	val list9: List<Int> = listOf(3, 2, 1)
	val list10: List<Int> = list9.sorted()

	println(list10[0] == 1)
}

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
}

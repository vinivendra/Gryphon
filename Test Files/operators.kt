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

fun main(args: Array<String>) {
	val x: Int = 0
	val y: Int = x + 1
	val z: Int = 2 + 3

	println(x)
	println(y)
	println(z)

	val multiplication: Int = 0 * 1
	val division: Int = 10 / 2
	val subtraction: Int = 3 - 1
	val sum: Int = 4 + 1

	println(multiplication)
	println(division)
	println(subtraction)
	println(sum)

	val multiplication2: Int = 0 * 1
	val division2: Int = 10 / 2
	val subtraction2: Int = 3 - 1
	val sum2: Int = 4 + 1

	println(multiplication2)
	println(division2)
	println(subtraction2)
	println(sum2)

	var multiplication3: Int = 0 * -1
	var division3: Int = -10 / 2
	var subtraction3: Int = -3 - 1
	var sum3: Int = 4 + -1

	println(multiplication3)
	println(division3)
	println(subtraction3)
	println(sum3)

	multiplication3 = 1 * 2
	division3 = 1 / 2
	subtraction3 = 1 - 2
	sum3 = 1 + 2

	println(multiplication3)
	println(division3)
	println(subtraction3)
	println(sum3)

	if (x == 0) {
		println("true")
	}

	if (x == 1) {
		println("false")
	}

	if (x != 1) {
		println("true")
	}
}

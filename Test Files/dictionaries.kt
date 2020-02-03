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
	val dictionaryA: Map<String, Int> = mapOf("a" to 1, "b" to 2, "c" to 3)
	val dictionaryB: Map<Int, Int> = mapOf()

	println(dictionaryA["a"])
	println(dictionaryA["b"])
	println(dictionaryA["c"])
	println(dictionaryA["d"])
	println(dictionaryB[0])

	val dictionary1: MutableMap<String, Int> = mutableMapOf("a" to 1, "b" to 2, "c" to 3)
	val dictionary2: MutableMap<String, Int> = dictionary1

	dictionary1["a"] = 10

	println(dictionary1["a"])
	println(dictionary1["b"])
	println(dictionary1["c"])
	println(dictionary1["d"])
	println(dictionary2["a"])
	println(dictionary2["b"])
	println(dictionary2["c"])
	println(dictionary2["d"])

	val dictionary3: MutableMap<String, Int> = mutableMapOf()

	println(dictionary3["a"])
	println(dictionary3["d"])
}

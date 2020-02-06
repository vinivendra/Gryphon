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
internal fun useClosure(closure: (String) -> Unit) {
	closure("Calling from function!")
}

internal fun defaultClosure(closure: (String) -> Unit = { println(it) }) {
	closure("Calling from default closure!")
}

fun main(args: Array<String>) {
	val printClosure: (String) -> Unit = { println(it) }

	printClosure("Hello, world!")

	val plusClosure: (Int, Int) -> Int = { a, b -> a + b }

	println(plusClosure(2, 3))

	useClosure(closure = printClosure)
	defaultClosure()

	val multiLineClosure: (Int) -> Unit = { a ->
			if (a == 10) {
				println("It's ten!")
			}
			else {
				println("It's not ten.")
			}
		}

	multiLineClosure(10)
	multiLineClosure(20)
}

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
internal val String.isString: Boolean
	get() {
		return true
	}
internal val String.world: String
	get() {
		return "World!"
	}

internal fun String.appendWorld(): String {
	return this + ", world!"
}

internal fun String.functionWithVariable() {
	var string: String = ", world!!"
	println("Hello${string}")
}

fun main(args: Array<String>) {
	println("${"Hello!".isString}")
	println("${"Hello!".world}")
	println("${"Hello".appendWorld()}")

	"bla".functionWithVariable()
}

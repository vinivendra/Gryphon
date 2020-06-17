//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license.md
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
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

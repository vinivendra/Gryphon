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
internal data class SupportedStruct(
	val x: Int = 0,
	val y: Int = 1
)

internal data class OtherSupportedStruct(
	val x: Int,
	val y: Int
)

internal data class NoInheritance(
	val x: Int,
	val y: Int
)

fun main(args: Array<String>) {
	val a: SupportedStruct = SupportedStruct()
	val b: OtherSupportedStruct = OtherSupportedStruct(x = 10, y = 20)

	println(a.x)
	println(a.y)
	println(b.x)
	println(b.y)
}

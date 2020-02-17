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

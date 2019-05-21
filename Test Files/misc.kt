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
typealias A = Int

open class B {
	open class C {
	}
}

typealias BC = B.C
typealias ListInt = List<Int>

internal fun f(a: Int?) {
	a ?: return
	println(a)
}

fun main(args: Array<String>) {
	var a: A = 0
	var bc: BC

	f(a = 10)

	println("==")

	f(a = null)

	println("==")
}

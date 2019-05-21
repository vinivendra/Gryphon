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
internal sealed class CalculatorError: Exception() {
	class InvalidCharacter: CalculatorError()
	class MultipleCharacters: CalculatorError()
	class NilInput: CalculatorError()
}

internal sealed class OtherError: Exception() {
	class OneInt(val int: Int): OtherError()
	class TwoInts(val int: Int, val int2: Int): OtherError()
	class IntAndString(val int: Int, val string: String): OtherError()
}

internal enum class NoInheritances {
	FOO_BAR,
	BAR_BAZ;

	companion object {
		operator fun invoke(rawValue: String): NoInheritances? {
			return when (rawValue) {
				"foo-bar" -> NoInheritances.FOO_BAR
				"barBaz" -> NoInheritances.BAR_BAZ
				else -> null
			}
		}
	}

	val rawValue: String
		get() {
			return when (this) {
				NoInheritances.FOO_BAR -> "foo-bar"
				NoInheritances.BAR_BAZ -> "barBaz"
			}
		}
}

internal enum class WithMembers {
	FOO_BAR,
	BAZ;

	internal fun a() {
	}

	internal fun b() {
	}
}

internal fun throwingFunc() {
	throw CalculatorError.InvalidCharacter()
}

internal fun otherThrowingFunc() {
	throwingFunc()
}

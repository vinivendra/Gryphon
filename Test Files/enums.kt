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
	Foo,
	Bar,
}

internal sealed class WithMembers {
	class Foo: WithMembers()
	class Bar: WithMembers()

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

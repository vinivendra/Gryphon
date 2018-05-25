internal sealed class CalculatorError: Exception() {
	class InvalidCharacter: CalculatorError()
	class MultipleCharacters: CalculatorError()
	class NilInput: CalculatorError()
}
internal fun throwingFunc() {
	throw CalculatorError.InvalidCharacter()
}

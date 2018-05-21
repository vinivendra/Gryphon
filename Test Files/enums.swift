enum CalculatorError: Error {
	case invalidCharacter
	case multipleCharacters
	case nilInput
}

func throwingFunc() throws {
	throw CalculatorError.invalidCharacter
}

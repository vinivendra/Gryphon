import Foundation

private func GRYInsert(_ a: String) { }

private func GRYDeclarations() {
	GRYInsert("package com.example.gryphon.calculator")
}

public enum CalculatorError: Error {
	case invalidCharacter
	case multipleCharacters
	case nilInput
}

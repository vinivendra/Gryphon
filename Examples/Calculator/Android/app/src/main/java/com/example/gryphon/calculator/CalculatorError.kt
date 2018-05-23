package com.example.gryphon.calculator

public sealed class CalculatorError: Exception() {
    class InvalidCharacter: CalculatorError()
    class MultipleCharacters: CalculatorError()
    class NilInput: CalculatorError()
}

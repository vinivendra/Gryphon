package com.example.gryphon.calculator

internal sealed class CalculatorError: Exception() {
    class InvalidCharacter: CalculatorError()
    class MultipleCharacters: CalculatorError()
    class NilInput: CalculatorError()
}

//enum class CalculatorException: Throwable {
//    invalidCharacter,
//    multipleCharacters,
//    nilInput;
//
//
//    fun message(): String {
//        when (this) {
//            invalidCharacter -> return "Invalid character exception.\nThe input is not a number between 0-9, an operator (+, -, *, /), D, C, =, or a period."
//            multipleCharacters-> return "Multiple characters exception.\nThe input contains more than one character."
//            nilInput-> return "Nil exception.\nThe input is nil."
//        }
//    }
//}

//class CalculatorException private constructor(override var message:String): Exception(message) {
//
//    enum class Type {
//        invalidCharacter,
//        multipleCharacters,
//        nilInput
//    }
//
//    companion object {
//        fun create(type: Type): CalculatorException {
//            when (type) {
//                Type.invalidCharacter -> return CalculatorException(message = "Invalid character exception.\nThe input is not a number between 0-9, an operator (+, -, *, /), D, C, =, or a period.")
//                Type.multipleCharacters-> return CalculatorException(message = "Multiple characters exception.\nThe input contains more than one character.")
//                Type.nilInput-> return CalculatorException(message = "Nil exception.\nThe input is nil.")
//            }
//        }
//    }
//}

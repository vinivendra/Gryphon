package com.example.gryphon.calculator

import org.junit.Test

import org.junit.Assert.*

/**
 * Example local unit test, which will execute on the development machine (host).
 *
 * See [testing documentation](http://d.android.com/tools/testing).
 */
class CalculatorUnitTests {

    var calculator: Calculator = Calculator()

    @Test
    fun testAddition() {
        calculator.input("6")
        calculator.input("+")
        calculator.input("2")
        calculator.input("=")

        assertEquals(calculator.displayValue, "8.0")
    }

    @Test
    fun testSubtraction() {
        calculator.input("1")
        calculator.input("9")
        calculator.input("-")
        calculator.input("2")
        calculator.input("=")

        assertEquals(calculator.displayValue, "17.0")
    }

    @Test
    fun testDivision() {
        calculator.input("6")
        calculator.input("*")
        calculator.input("2")
        calculator.input("=")

        assertEquals(calculator.displayValue, "12.0")
    }

    @Test
    fun testMultiplication() {
        calculator.input("6")
        calculator.input("*")
        calculator.input("2")
        calculator.input("=")

        assertEquals(calculator.displayValue, "12.0")
    }

    @Test
    fun testSubtractionNegativeResult() {
        calculator.input("6")
        calculator.input("-")
        calculator.input("2")
        calculator.input("4")
        calculator.input("=")

        assertEquals(calculator.displayValue, "-18.0")
    }

    @Test
    fun testClearLastEntry() {
        calculator.input("7")
        calculator.input("+")
        calculator.input("3")
        calculator.input("C")
        calculator.input("4")
        calculator.input("=")

        assertEquals(calculator.displayValue, "11.0")
    }

    @Test
    fun testClearComputation() {
        calculator.input("C")
        calculator.input("7")
        calculator.input("+")
        calculator.input("3")
        calculator.input("C")
        calculator.input("C")

        assertEquals(calculator.displayValue, "0")
    }

    @Test
    fun testInputException() {
        var exceptionWasCaught = false
        try {
            calculator.input("67")
        }
        catch (e: CalculatorError.MultipleCharacters) {
            exceptionWasCaught = true
        }
        assertTrue(exceptionWasCaught)

        exceptionWasCaught = false
        try {
            calculator.input("j")
        }
        catch (e: CalculatorError.InvalidCharacter) {
            exceptionWasCaught = true
        }
        assertTrue(exceptionWasCaught)

        exceptionWasCaught = false
        try {
            calculator.input(null)
        }
        catch (e: CalculatorError.NilInput) {
            exceptionWasCaught = true
        }
        assertTrue(exceptionWasCaught)
    }
}
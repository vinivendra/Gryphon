package com.example.gryphon.calculator

class Calculator {
    val period: String = "."
    var display: String = ""
    var leftOperand: Double? = null
    var operatorValue: String? = null
    var isLastCharacterOperator: Boolean = false
    val displayValue: String
        get() {
            if (!(display.isEmpty())) {
                return this.display
            }
            else {
                return "0"
            }
        }
    public fun input(input: String?) {
        val input: String? = input
        if (!(input != null)) {
            throw CalculatorError.NilInput()
        }
        if (!(input.isValidCharacter)) {
            throw CalculatorError.InvalidCharacter()
        }
        if (!(input.length == 1)) {
            throw CalculatorError.MultipleCharacters()
        }
        if (input.isValidDigit) {
            if (this.isLastCharacterOperator) {
                this.display = input
                this.isLastCharacterOperator = false
            }
            else if (!input.isPeriod || !(this.display.contains(this.period))) {
                this.display += input
            }
        }
        else if (input.isOperator || input.isEqualSign) {
            if ((this.operatorValue == null) && !(input.isEqualSign)) {
                this.leftOperand = displayValue.toDouble()
                this.operatorValue = input
            }
            else {
                val sign: String? = this.operatorValue
                val operand: Double? = this.leftOperand
                val rightOperand: Double? = displayValue.toDouble()
                if (sign != null && operand != null && rightOperand != null) {
                    val result: Double? = this.operation(left = operand, right = rightOperand, sign = sign)
                    if (result != null) {
                        this.display = "${(result)}"
                    }
                }
                if (input.isEqualSign) {
                    this.operatorValue = null
                }
                else {
                    this.operatorValue = input
                }
            }
            this.isLastCharacterOperator = true
        }
        else if (input.isClear) {
            if (!(display.isEmpty())) {
                this.display = ""
            }
            else {
                this.operatorValue = null
            }
        }
        else if (input.isDelete) {
            if (!display.isEmpty()) {
                this.display = display.dropLast(1)
            }
            this.isLastCharacterOperator = false
        }
    }
    internal fun operation(left: Double, right: Double, sign: String): Double? {
        if (sign == "+") {
            return left + right
        }
        else if (sign == "-") {
            return left - right
        }
        else if (sign == "*") {
            return left * right
        }
        else if (sign == "/") {
            return left / right
        }
        else {
            return null
        }
    }
}

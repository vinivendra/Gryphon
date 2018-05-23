package com.example.gryphon.calculator
val String.isDelete: Boolean
    get() {
        return (this == "D")
    }
val String.isPeriod: Boolean
    get() {
        return (this == ".")
    }
val String.isClear: Boolean
    get() {
        return (this == "C")
    }
val String.isValidDigit: Boolean
    get() {
        val digits: String = "0123456789."
        return digits.contains(this)
    }
val String.isOperator: Boolean
    get() {
        val operators: String = "+-*/"
        return operators.contains(this)
    }
val String.isEqualSign: Boolean
    get() {
        return (this == "=")
    }
val String.isValidCharacter: Boolean
    get() {
        return (this.isValidDigit || this.isOperator || this.isDelete || this.isClear || this.isPeriod || this.isEqualSign)
    }
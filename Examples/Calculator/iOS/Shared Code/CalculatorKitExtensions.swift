import Foundation

private func GRYInsert(_ a: String) { }

private func GRYDeclarations() {
	GRYInsert("package com.example.gryphon.calculator")
}

extension String {
	
	/// Determines whether the string is the Delete charater.
	var isDelete: Bool {
		return (self == "D")
	}
	
	/// Determines whether the string is a period.
	var isPeriod: Bool {
		return (self == ".")
	}
	
	/// Determines whether the string is the Clear charater.
	var isClear: Bool {
		return (self == "C")
	}
	
	/// Determines whether the string is a period or a number between 0 and 9.
	var isValidDigit: Bool {
		let digits = "0123456789."
		return digits.contains(self)
	}
	
	/// Determines whether the string is an operator such as +, -, *, or /.
	var isOperator: Bool {
		let operators = "+-*/"
		return operators.contains(self)
	}
	
	/// Determines whether the string is an equal sign.
	var isEqualSign: Bool {
		return (self == "=")
	}
	
	/// Determines whether a string is a valid character such as a digit, a.
	var isValidCharacter: Bool {
		return ( isValidDigit || isOperator || isDelete || isClear || isPeriod || isEqualSign)
	}
}

import Foundation

public enum CalculatorError: Error {
	case invalidCharacter
	case multipleCharacters
	case nilInput
}
import Foundation

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
import Foundation

private func GRYInsert(_ a: String) { }

private func GRYAlternative<T>(swift swiftExpression: T, kotlin kotlinExpression: String) -> T {
	return swiftExpression
}

private func GRYDeclarations() {
	GRYInsert("package com.example.gryphon.calculator")
}

open class Calculator {
	fileprivate let period = "."
	fileprivate var display: String = ""
	fileprivate var leftOperand: Double?
	fileprivate var operatorValue: String? = nil
	fileprivate var isLastCharacterOperator = false
	
	public var displayValue: String {
		get {
			if !(GRYAlternative(swift: display.isEmpty, kotlin: "display.isEmpty()")) {
				return display
			}
			else {
				return "0"
			}
		}
	}
	
	public func input(_ input: String?) throws {
		
		/*
		We must first check that the inputted character is a number between 0 and 9, an operator (+, -, *, /),
		"D", "C", "=", or a period before we can proceed.
		*/
		guard let input = input else {
			throw CalculatorError.nilInput
		}
		
		guard input.isValidCharacter else {
			throw CalculatorError.invalidCharacter
		}
		
		guard GRYAlternative(swift: input.count, kotlin: "input.length") == 1 else {
			throw CalculatorError.multipleCharacters
		}
		
		// If the inputted character is a number (between 0 and 9) or a period, update the display.
		if input.isValidDigit {
			
			if isLastCharacterOperator {
				
				display = input
				isLastCharacterOperator = false
			}
			else if !input.isPeriod || !(display.contains(period)) {
				// Add it to the current display.
				display += input
			}
		}
			
			/*
			If the inputted character is an operator, save it in operatorValue and the current displayed value in leftOperand.
			If the inputted character is an equal sign, call the operation function to perform a calculation
			using leftOperand, the current displayed value, and operatorValue, then save the result in the display variable.
			*/
		else if input.isOperator || input.isEqualSign {
			
			if (operatorValue == nil) && !(input.isEqualSign) {
				
				leftOperand = GRYAlternative(swift: Double(displayValue), kotlin: "displayValue.toDouble()")
				operatorValue = input
			}
			else {
				if let sign = operatorValue, let operand = leftOperand, let rightOperand = GRYAlternative(swift: Double(displayValue), kotlin: "displayValue.toDouble()") {
					//
					if let result = operation(left: operand, right: rightOperand, sign: sign) {
						//						// Update the display with the operation's result.
						display = "\(result)"
					}
				}
				
				if input.isEqualSign {
					operatorValue = nil
				}
				else {
					operatorValue = input
				}
			}
			
			isLastCharacterOperator = true
		}
			// if the inputted character is "C" and there is something displayed, clear it. Clear the saved operator, otherwise.
		else if input.isClear {
			if !(GRYAlternative(swift: display.isEmpty, kotlin: "display.isEmpty()")) {
				display = ""
			}
			else {
				operatorValue = nil
			}
		}
			// If the inputted character is "D" and there is something displayed, remove its last character.
		else if input.isDelete {
			if !GRYAlternative(swift: display.isEmpty, kotlin: "display.isEmpty()") {
				display = GRYAlternative(swift: String(display.dropLast()), kotlin: "display.substring(0, display.length - 1)")
			}
			isLastCharacterOperator = false
		}
	}
	
	
	/// - returns: Result of an arithmetic operation using the provided operands and operator.
	func operation(left: Double, right: Double, sign: String) -> Double? {
		if sign == "+" {
			return left + right
		}
		else if sign == "-" {
			return left - right
		}
		else if sign == "*" {
			return left * right
		}
		else if sign == "/" {
			return left / right
		}
		else {
			return nil
		}
	}
}

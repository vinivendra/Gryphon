/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation

public struct TranspilationTemplate {
	let expression: Expression
	let string: String

	static var templates = [TranspilationTemplate]()
}

public class RecordTemplatesTranspilationPass: TranspilationPass {
	override func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclarationData)
		-> ArrayClass<Statement>
	{
		if functionDeclaration.prefix == "gryphonTemplates",
			functionDeclaration.parameters.isEmpty,
			let statements = functionDeclaration.statements
		{
			let expressions = statements.compactMap
			{ (statement: Statement) -> Expression? in
				if case let .expressionStatement(expression: expression) = statement {
					return expression
				}
				else {
					return nil
				}
			}

			var previousExpression: Expression?
			for expression in expressions {
				if let templateExpression = previousExpression {
					guard let literalString = getStringLiteralOrSum(expression) else {
						continue
					}
					TranspilationTemplate.templates.insert(
						TranspilationTemplate(
							expression: templateExpression, string: literalString),
						at: 0)
					previousExpression = nil
				}
				else {
					previousExpression = expression
				}
			}

			return []
		}

		return super.replaceFunctionDeclaration(functionDeclaration)
	}

	/// Some String literals are written as sums of string literals (i.e. "a" + "b") or they'd be
	/// too large to fit in one line. This method should detect Strings both with and without sums.
	private func getStringLiteralOrSum(_ expression: Expression) -> String? {
		if case let .literalStringExpression(value: value) = expression {
			return value
		}
		else if case let .binaryOperatorExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression,
			operatorSymbol: "+",
			type: "String") = expression,
			let leftString = getStringLiteralOrSum(leftExpression),
			let rightString = getStringLiteralOrSum(rightExpression)
		{
			return leftString + rightString
		}
		else {
			return nil
		}
	}
}

public class ReplaceTemplatesTranspilationPass: TranspilationPass {
	override func replaceExpression(_ expression: Expression) -> Expression {
		for template in TranspilationTemplate.templates {
			if let matches = expression.matches(template.expression) {
				let replacedMatches = matches.mapValues {
					self.replaceExpression($0)
				}
				return .templateExpression(
					pattern: template.string,
					matches: DictionaryClass(replacedMatches))
			}
		}
		return super.replaceExpression(expression)
	}
}

extension Expression {
	func matches(_ template: Expression) -> [String: Expression]? {
		var result = [String: Expression]()
		let success = matches(template, &result)
		if success {
			return result
		}
		else {
			return nil
		}
	}

	private func matches(
		_ template: Expression, _ matches: inout [String: Expression]) -> Bool
	{
		if case let .declarationReferenceExpression(
				data: templateExpression) = template,
			templateExpression.identifier.hasPrefix("_"),
			self.isOfType(templateExpression.type)
		{
			matches[templateExpression.identifier] = self
			return true
		}
		else {
			switch (self, template) {
			case let (
				.literalCodeExpression(string: leftString),
				.literalCodeExpression(string: rightString)):

				return leftString == rightString
			case let (
				.parenthesesExpression(expression: leftExpression),
				.parenthesesExpression(expression: rightExpression)):

				return leftExpression.matches(rightExpression, &matches)
			case let (
				.forceValueExpression(expression: leftExpression),
				.forceValueExpression(expression: rightExpression)):

				return leftExpression.matches(rightExpression, &matches)
			case let
				(.declarationReferenceExpression(data: leftExpression),
				 .declarationReferenceExpression(data: rightExpression)):

				return leftExpression.identifier == rightExpression.identifier &&
					leftExpression.type.isSubtype(of: rightExpression.type) &&
					leftExpression.isImplicit == rightExpression.isImplicit
			case let
				(.typeExpression(type: leftType),
				 .typeExpression(type: rightType)):

				return leftType.isSubtype(of: rightType)
			case let
				(.typeExpression(type: leftType),
				 .declarationReferenceExpression(data: rightExpression)):

				guard declarationExpressionMatchesImplicitTypeExpression(rightExpression) else {
					return false
				}
				let expressionType = String(rightExpression.type.dropLast(".Type".count))
				return leftType.isSubtype(of: expressionType)
			case let
				(.declarationReferenceExpression(data: leftExpression),
				 .typeExpression(type: rightType)):
				guard declarationExpressionMatchesImplicitTypeExpression(leftExpression) else {
					return false
				}
				let expressionType = String(leftExpression.type.dropLast(".Type".count))
				return expressionType.isSubtype(of: rightType)
			case let
				(.subscriptExpression(
					subscriptedExpression: leftSubscriptedExpression,
					indexExpression: leftIndexExpression, type: leftType),
				 .subscriptExpression(
					subscriptedExpression: rightSubscriptedExpression,
					indexExpression: rightIndexExpression, type: rightType)):

					return leftSubscriptedExpression.matches(rightSubscriptedExpression, &matches)
						&& leftIndexExpression.matches(rightIndexExpression, &matches)
						&& leftType.isSubtype(of: rightType)
			case let
				(.arrayExpression(elements: leftElements, type: leftType),
				 .arrayExpression(elements: rightElements, type: rightType)):

				var result = true
				for (leftElement, rightElement) in zip(leftElements, rightElements) {
					result = result && leftElement.matches(rightElement, &matches)
				}
				return result && (leftType.isSubtype(of: rightType))
			case let
				(.dotExpression(
					leftExpression: leftLeftExpression, rightExpression: leftRightExpression),
				 .dotExpression(
					leftExpression: rightLeftExpression, rightExpression: rightRightExpression)):

				return leftLeftExpression.matches(rightLeftExpression, &matches) &&
					leftRightExpression.matches(rightRightExpression, &matches)
			case let
				(.binaryOperatorExpression(
					leftExpression: leftLeftExpression, rightExpression: leftRightExpression,
					operatorSymbol: leftOperatorSymbol, type: leftType),
				 .binaryOperatorExpression(
					leftExpression: rightLeftExpression, rightExpression: rightRightExpression,
					operatorSymbol: rightOperatorSymbol, type: rightType)):

				return leftLeftExpression.matches(rightLeftExpression, &matches) &&
					leftRightExpression.matches(rightRightExpression, &matches) &&
					(leftOperatorSymbol == rightOperatorSymbol) &&
					(leftType.isSubtype(of: rightType))
			case let
				(.prefixUnaryExpression(
					expression: leftExpression, operatorSymbol: leftOperatorSymbol, type: leftType),
				 .prefixUnaryExpression(
					expression: rightExpression, operatorSymbol: rightOperatorSymbol,
					type: rightType)):

				return leftExpression.matches(rightExpression, &matches) &&
					(leftOperatorSymbol == rightOperatorSymbol)
					&& (leftType.isSubtype(of: rightType))
			case let
				(.postfixUnaryExpression(
					expression: leftExpression, operatorSymbol: leftOperatorSymbol, type: leftType),
				 .postfixUnaryExpression(
					expression: rightExpression, operatorSymbol: rightOperatorSymbol,
					type: rightType)):

				return leftExpression.matches(rightExpression, &matches) &&
					(leftOperatorSymbol == rightOperatorSymbol)
					&& (leftType.isSubtype(of: rightType))
			case let
				(.callExpression(data: leftCallExpression),
				 .callExpression(data: rightCallExpression)):

				return leftCallExpression.function.matches(
						rightCallExpression.function, &matches) &&
					leftCallExpression.parameters.matches(
						rightCallExpression.parameters, &matches) &&
					leftCallExpression.type.isSubtype(of: rightCallExpression.type)
			case let
				(.literalIntExpression(value: leftValue),
				 .literalIntExpression(value: rightValue)):

				return leftValue == rightValue
			case let
				(.literalDoubleExpression(value: leftValue),
				 .literalDoubleExpression(value: rightValue)):

				return leftValue == rightValue
			case let
				(.literalBoolExpression(value: leftValue),
				 .literalBoolExpression(value: rightValue)):

				return leftValue == rightValue
			case let
				(.literalStringExpression(value: leftValue),
				 .literalStringExpression(value: rightValue)):

				return leftValue == rightValue
			case let
				(.literalStringExpression(value: leftValue),
				 .declarationReferenceExpression):

				let characterExpression = Expression.literalCharacterExpression(value: leftValue)
				return characterExpression.matches(template, &matches)
			case (.nilLiteralExpression, .nilLiteralExpression):
				return true
			case let
				(.interpolatedStringLiteralExpression(expressions: leftExpressions),
				 .interpolatedStringLiteralExpression(expressions: rightExpressions)):

				var result = true
				for (leftExpression, rightExpression) in zip(leftExpressions, rightExpressions) {
					result = result && leftExpression.matches(rightExpression, &matches)
				}
				return result
			case let
				(.tupleExpression(pairs: leftPairs),
				 .tupleExpression(pairs: rightPairs)):

				// Check manually for matches in trailing closures (that don't have labels in code
				// but do in templates)
				if leftPairs.count == 1,
					let onlyLeftPair = leftPairs.first,
					case let .parenthesesExpression(
						expression: closureExpression) = onlyLeftPair.expression,
					case .closureExpression = closureExpression,
					rightPairs.count == 1,
					let onlyRightPair = rightPairs.first
				{
					// Unwrap a redundand parentheses expression if needed
					if case let .parenthesesExpression(
						expression: templateExpression) = onlyRightPair.expression
					{
						return closureExpression.matches(templateExpression, &matches)
					}
					else {
						return closureExpression.matches(onlyRightPair.expression, &matches)
					}
				}
				else {
					var result = true
					for (leftPair, rightPair) in zip(leftPairs, rightPairs) {
						result = result &&
							leftPair.expression.matches(rightPair.expression, &matches) &&
							leftPair.label == rightPair.label
					}
					return result
				}
			case let
				(.tupleShuffleExpression(
					labels: leftLabels, indices: leftIndices, expressions: leftExpressions),
				 .tupleShuffleExpression(
					labels: rightLabels, indices: rightIndices, expressions: rightExpressions)):

				var result = (leftLabels == rightLabels) && (leftIndices == rightIndices)
				for (leftExpression, rightExpression) in zip(leftExpressions, rightExpressions) {
					result = result && leftExpression.matches(rightExpression, &matches)
				}
				return result
			default:
				return false
			}
		}
	}

	/**
	In a static context, some type expressions can be omitted. When that happens, they get
	translated as declaration references instead of type expressions. However, thwy should still
	match type expressions, as they're basically the same. This method should detect those cases.

	Example:

	```
	class A {
		static func a() { }
		static func b() {
			a() // implicitly this is A.a(), and the implicit `A` gets dumped as a declaration
			// reference expression instead of a type expression.
		}
	```
	**/
	private func declarationExpressionMatchesImplicitTypeExpression(
		_ expression: DeclarationReferenceData) -> Bool
	{
		if expression.identifier == "self",
			expression.type.hasSuffix(".Type"),
			expression.isImplicit
		{
			return true
		}
		else {
			return true
		}
	}

	func isOfType(_ superType: String) -> Bool {
		guard let type = self.type else {
			return false
		}

		return type.isSubtype(of: superType)
	}
}

fileprivate extension String {
	func isSubtype(of superType: String) -> Bool {
		// Check common cases
		if self == superType {
			return true
		}
		else if superType == "Any" ||
			superType == "Hash" ||
			superType == "Compare" ||
			superType == "MyOptional"
		{
			return true
		}
		else if superType == "MyOptional?" {
			return self.hasSuffix("?")
		}

		// Handle tuples
		if Utilities.isInEnvelopingParentheses(self), Utilities.isInEnvelopingParentheses(superType)
		{
			let selfContents = String(self.dropFirst().dropLast())
			let superContents = String(superType.dropFirst().dropLast())

			let selfComponents = selfContents.split(withStringSeparator: ", ")
			let superComponents = superContents.split(withStringSeparator: ", ")

			guard selfComponents.count == superComponents.count else {
				return false
			}

			for (selfComponent, superComponent) in zipToClass(selfComponents, superComponents) {
				guard selfComponent.isSubtype(of: superComponent) else {
					return false
				}
			}

			return true
		}

		// Simplify the types
		let simpleSelf = simplifyType(string: self)
		let simpleSuperType = simplifyType(string: superType)
		if simpleSelf != self || simpleSuperType != superType {
			return simpleSelf.isSubtype(of: simpleSuperType)
		}

		// Handle optionals
		if self.last == "?", superType.last == "?" {
			let newSelf = String(self.dropLast())
			let newSuperType = String(superType.dropLast())
			return newSelf.isSubtype(of: newSuperType)
		}
		else if superType.last == "?" {
			let newSuperType = String(superType.dropLast())
			return self.isSubtype(of: newSuperType)
		}

		// Analyze components of function types
		if superType.contains(" -> ") {
			guard self.contains(" -> ") else {
				return false
			}

			return true
		}

		// Handle arrays and dictionaries
		if self.first == "[", self.last == "]", superType.first == "[", superType.last == "]" {
			if self.contains(":") && superType.contains(":") {
				let selfKeyValue =
					String(self.dropFirst().dropLast()).split(withStringSeparator: " : ")
				let superKeyValue =
					String(superType.dropFirst().dropLast()).split(withStringSeparator: " : ")
				let selfKey = selfKeyValue[0]
				let selfValue = selfKeyValue[1]
				let superKey = superKeyValue[0]
				let superValue = superKeyValue[1]
				return selfKey.isSubtype(of: superKey) && selfValue.isSubtype(of: superValue)
			}
			else if !self.contains(":") && !superType.contains(":") {
				let selfElement = String(self.dropFirst().dropLast())
				let superTypeElement = String(superType.dropFirst().dropLast())
				return selfElement.isSubtype(of: superTypeElement)
			}
		}

		// Handle generics
		if self.contains("<"), self.last == ">", superType.contains("<"), superType.last == ">" {
			let selfStartGenericsIndex = self.firstIndex(of: "<")!
			let superTypeStartGenericsIndex = superType.firstIndex(of: "<")!

			let selfGenericArguments =
				String(self[selfStartGenericsIndex...].dropFirst().dropLast())
			let superTypeGenericArguments =
				String(superType[superTypeStartGenericsIndex...].dropFirst().dropLast())

			let selfTypeComponents = selfGenericArguments.split(withStringSeparator: ", ")
			let superTypeComponents = superTypeGenericArguments.split(withStringSeparator: ", ")

			guard superTypeComponents.count == selfTypeComponents.count else {
				return false
			}

			for (selfTypeComponent, superTypeComponent) in
				zip(selfTypeComponents, superTypeComponents)
			{
				if !selfTypeComponent.isSubtype(of: superTypeComponent) {
					return false
				}
			}

			return true
		}
		else if self.contains("<"), self.last == ">" {
			let typeWithoutGenerics = String(self.prefix { $0 != "<" })
			return typeWithoutGenerics.isSubtype(of: superType)
		}
		else if superType.contains("<"), superType.last == ">" {
			let typeWithoutGenerics = String(superType.prefix { $0 != "<" })
			return self.isSubtype(of: typeWithoutGenerics)
		}

		// If no subtype cases were met, say it's not a subtype
		return false
	}
}

private func simplifyType(string: String) -> String {
	// Deal with standard library types that can be handled as other types
	if let result = Utilities.getTypeMapping(for: string) {
		return result
	}

	// Treat ArrayClass as Array
	if string.hasPrefix("ArrayClass<"), string.last == ">" {
		let elementType = String(string.dropFirst("ArrayClass<".count).dropLast())
		return "[\(elementType)]"
	}

	// Treat Slice as Array
	if string.hasPrefix("Slice<ArrayClass<"), string.hasSuffix(">>") {
		let elementType =
			String(string.dropFirst("Slice<ArrayClass<".count).dropLast(">>".count))
		return "[\(elementType)]"
	}
	else if string.hasPrefix("ArraySlice<"), string.hasSuffix(">") {
		let elementType = String(string.dropFirst("ArraySlice<".count).dropLast())
		return "[\(elementType)]"
	}

	// Treat DictionaryClass as Dictionary
	if string.hasPrefix("DictionaryClass<"), string.last == ">" {
		let keyValue = String(string.dropFirst("DictionaryClass<".count).dropLast())
			.split(withStringSeparator: ", ")
		let key = keyValue[0]
		let value = keyValue[1]
		return "[\(key) : \(value)]"
	}

	// Convert Array<T> into [T]
	if string.hasPrefix("Array<"), string.last == ">" {
		let elementType = String(string.dropFirst("Reference<".count).dropLast())
		return "[\(elementType)]"
	}

	// Remove parentheses
	if Utilities.isInEnvelopingParentheses(string) {
		return String(string.dropFirst().dropLast())
	}

	// Handle inout types
	if string.hasPrefix("inout ") {
		return String(string.dropFirst("inout ".count))
	}

	// Handle `__owned` types
	if string.hasPrefix("__owned ") {
		return String(string.dropFirst("__owned ".count))
	}

	return string
}

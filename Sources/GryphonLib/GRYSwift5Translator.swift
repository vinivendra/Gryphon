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

public class GRYSwift5Translator: GRYSwift4Translator {
	override internal func translate(expression: GRYSwiftAST) throws -> GRYExpression {
		switch expression.name {
		case "Interpolated String Literal Expression":
			if let tapExpression = expression.subtree(named: "Tap Expression"),
				let braceStatement = tapExpression.subtree(named: "Brace Statement")
			{
				return try translate(interpolatedStringLiteralExpression: braceStatement)
			}
			else {
				return try unexpectedExpressionStructureError(
					"Expected the Interpolated String Literal Expression to contain a Tap" +
					"Expression containing a Brace Statement containing the String " +
					"interpolation contents",
					AST: expression)
			}
		default:
			return try super.translate(expression: expression)
		}
	}

	override func translate(interpolatedStringLiteralExpression: GRYSwiftAST)
		throws -> GRYExpression
	{
		try ensure(
			AST: interpolatedStringLiteralExpression,
			isNamed: "Brace Statement")

		var expressions = [GRYExpression]()

		for callExpression in interpolatedStringLiteralExpression.subtrees.dropFirst() {
			guard callExpression.name == "Call Expression",
				let parenthesesExpression = callExpression.subtree(named: "Parentheses Expression"),
				let expression = parenthesesExpression.subtrees.first else
			{
				return try unexpectedExpressionStructureError(
					"Expected the brace statement to contain only Call Expressions containing " +
					"Parentheses Expressions containing the relevant expressions.",
					AST: interpolatedStringLiteralExpression)
			}

			let translatedExpression = try translate(expression: expression)
			expressions.append(translatedExpression)
		}

		return .interpolatedStringLiteralExpression(expressions: expressions)
	}

	override func translate(arrayExpression: GRYSwiftAST) throws -> GRYExpression {
		try ensure(AST: arrayExpression, isNamed: "Array Expression")

		// Drop the "Semantic Expression" at the end
		let expressionsToTranslate = arrayExpression.subtrees.dropLast()

		let expressionsArray = try expressionsToTranslate.map(translate(expression:))

		guard let rawType = arrayExpression["type"] else {
			return try unexpectedExpressionStructureError(
				"Failed to get type", AST: arrayExpression)
		}
		let type = cleanUpType(rawType)

		return .arrayExpression(elements: expressionsArray, type: type)
	}

	override func translate(asNumericLiteral callExpression: GRYSwiftAST) throws -> GRYExpression {
		let expression = try super.translate(asNumericLiteral: callExpression)

		guard let tupleExpression = callExpression.subtree(named: "Tuple Expression"),
			let integerLiteralExpression = tupleExpression
				.subtree(named: "Integer Literal Expression") else
		{
			return try unexpectedExpressionStructureError(
				"Expected numeric literal to have a Tuple Expression containing an Integer " +
				"Literal Expression", AST: callExpression)
		}

		// Negative literals in Swift 5 aren't wrapped by a unary operator, so we have do wrap them
		// manually. Swift 4 integer literals also (redundantly) contain "negative".
		if integerLiteralExpression.standaloneAttributes.contains("negative") {

			// Assumes numeric literal expressions always know their types, which they do at the
			// moment of writing this code
			return .prefixUnaryExpression(
				expression: expression, operatorSymbol: "-", type: expression.type!)
		}
		else {
			return expression
		}
	}
}

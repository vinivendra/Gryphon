//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

@testable import GryphonLib
import XCTest

class SwiftSyntaxDecoderTest: XCTestCase {
	/// Tests to be run when using Swift on Linux
	static var allTests = [
		("test", test),
	]

	// MARK: - Tests
	func test() {
		do {
			Compiler.clearIssues()

			let testName = "swiftSyntax"
			let testCasePath = TestUtilities.testCasesPath + testName
			let gryphonAST = try Compiler.transpileGryphonRawASTs(
				fromInputFiles: [testCasePath.withExtension(.swift)],
				withContext: TranspilationContext(
					indentationString: "\t",
					defaultsToFinal: false,
					xcodeProjectPath: nil,
					pathConfigurations: [:],
					target: nil,
					swiftCompilationArguments: [testCasePath.withExtension(.swift)],
					absolutePathToSDK: nil))
				.first!

			// Check if the decoded statements are as we expect them
			var statementIterator = gryphonAST.statements.makeIterator()

			// Operators
			// - Multiplication over addition
			// `1 + 2 * 3`
			var testPassed = false
			var statement = statementIterator.next()!
			if let expressionStatement = statement as? ExpressionStatement,
				let additionExpression =
					expressionStatement.expression as? BinaryOperatorExpression,
				additionExpression.operatorSymbol == "+",
				let multiplicationExpression =
					additionExpression.rightExpression as? BinaryOperatorExpression,
				multiplicationExpression.operatorSymbol == "*"
			{
				testPassed = true
			}
			XCTAssert(testPassed, "Expected multiplication to have precedence over addition.\n" +
				"Range: \(String(describing: statement.range))\n" +
				"Statement:\n\(statement.prettyDescription())")

			// `1 * 2 + 3`
			testPassed = false
			statement = statementIterator.next()!
			if let expressionStatement = statement as? ExpressionStatement,
				let additionExpression =
					expressionStatement.expression as? BinaryOperatorExpression,
				additionExpression.operatorSymbol == "+",
				let multiplicationExpression =
			additionExpression.leftExpression as? BinaryOperatorExpression,
				multiplicationExpression.operatorSymbol == "*"
			{
				testPassed = true
			}
			XCTAssert(testPassed, "Expected multiplication to have precedence over addition.\n" +
				"Range: \(String(describing: statement.range))\n" +
				"Statement:\n\(statement.prettyDescription())")

			// - Left associativity of addition
			// `1 + 2 + 3`
			testPassed = false
			statement = statementIterator.next()!
			if let expressionStatement = statement as? ExpressionStatement,
				let firstAdditionExpression =
					expressionStatement.expression as? BinaryOperatorExpression,
				firstAdditionExpression.operatorSymbol == "+",
				let secondAdditionExpression =
					firstAdditionExpression.leftExpression as? BinaryOperatorExpression,
				secondAdditionExpression.operatorSymbol == "+"
			{
				testPassed = true
			}
			XCTAssert(testPassed, "Expected addition to be left associative.\n" +
				"Range: \(String(describing: statement.range))\n" +
				"Statement:\n\(statement.prettyDescription())")

			// - Parentheses
			// `2 * (3 + 4)`
			testPassed = false
			statement = statementIterator.next()!
			if let expressionStatement = statement as? ExpressionStatement,
				let multiplicationExpression =
					expressionStatement.expression as? BinaryOperatorExpression,
				multiplicationExpression.operatorSymbol == "*",
				let tupleExpression =
					multiplicationExpression.rightExpression as? TupleExpression,
				tupleExpression.pairs.count == 1,
 				let onlyPair = tupleExpression.pairs.first,
				onlyPair.label == nil,
				let additionExpression =
					onlyPair.expression as? BinaryOperatorExpression,
				additionExpression.operatorSymbol == "+"
			{
				testPassed = true
			}
			XCTAssert(testPassed, "Expected parentheses to take precedence over other operators.\n" +
				"Range: \(String(describing: statement.range))\n" +
				"Statement:\n\(statement.prettyDescription())")

			// - Addition over casts
			// `1 + 0 as Int`
			testPassed = false
			statement = statementIterator.next()!
			if let expressionStatement = statement as? ExpressionStatement,
				let castingExpression =
					expressionStatement.expression as? BinaryOperatorExpression,
				castingExpression.operatorSymbol == "as",
				castingExpression.typeName == "Int",
				let additionExpression =
					castingExpression.leftExpression as? BinaryOperatorExpression,
				additionExpression.operatorSymbol == "+"
			{
				testPassed = true
			}
			XCTAssert(testPassed, "Expected addition operator to have precedence over casting.\n" +
				"Range: \(String(describing: statement.range))\n" +
				"Statement:\n\(statement.prettyDescription())")

			// `0 as? Int`
			testPassed = false
			statement = statementIterator.next()!
			if let expressionStatement = statement as? ExpressionStatement,
				let castingExpression =
					expressionStatement.expression as? BinaryOperatorExpression,
				castingExpression.operatorSymbol == "as?",
				castingExpression.typeName == "Int?",
				let typeExpression = castingExpression.rightExpression as? TypeExpression,
				typeExpression.typeName == "Int"
			{
				testPassed = true
			}
			XCTAssert(testPassed, "Expected optional casts to have optional versions of the " +
				"casted types.\n" +
				"Range: \(String(describing: statement.range))\n" +
				"Statement:\n\(statement.prettyDescription())")

			// - Prefix unary expressions
			// `-1 + -2 * -3`
			testPassed = false
			statement = statementIterator.next()!
			if let expressionStatement = statement as? ExpressionStatement,
				let additionExpression =
					expressionStatement.expression as? BinaryOperatorExpression,
				additionExpression.operatorSymbol == "+",
				additionExpression.leftExpression is PrefixUnaryExpression,
				let multiplicationExpression =
					additionExpression.rightExpression as? BinaryOperatorExpression,
				multiplicationExpression.operatorSymbol == "*",
				multiplicationExpression.leftExpression is PrefixUnaryExpression,
				multiplicationExpression.rightExpression is PrefixUnaryExpression
			{
				testPassed = true
			}
			XCTAssert(testPassed, "Expected prefix operators to have higher precedence than " +
				"binary operators.\n" +
				"Range: \(String(describing: statement.range))\n" +
				"Statement:\n\(statement.prettyDescription())")

			// - Assignments over other operators
			// `x = 1 + 2`
			testPassed = false
			statement = statementIterator.next()! // Skip `var x = 1 + 2`
			statement = statementIterator.next()!
			if let assignmentStatement = statement as? AssignmentStatement,
				let additionExpression =
					assignmentStatement.rightHand as? BinaryOperatorExpression,
				additionExpression.operatorSymbol == "+"
			{
				testPassed = true
			}
			XCTAssert(testPassed, "Expected assignment operator to have precedence over " +
				"addition.\n" +
				"Range: \(String(describing: statement.range))\n" +
				"Statement:\n\(statement.prettyDescription())")

			// - Discarded assignments
			// `_ = 1 + 2`
			testPassed = false
			statement = statementIterator.next()!
			if let expressionStatement = statement as? ExpressionStatement,
				let additionExpression =
					expressionStatement.expression as? BinaryOperatorExpression,
				additionExpression.operatorSymbol == "+"
			{
				testPassed = true
			}
			XCTAssert(testPassed, "Expected `_ = expression` become just the expression.\n" +
				"Range: \(String(describing: statement.range))\n" +
				"Statement:\n\(statement.prettyDescription())")

			// - Other operators over ternary expressions
			// `0 == 1 ? 2 == 3 : 4 == 5`
			testPassed = false
			statement = statementIterator.next()!
			if let expressionStatement = statement as? ExpressionStatement,
				let ifExpression =
					expressionStatement.expression as? IfExpression,
				let condition = ifExpression.condition as? BinaryOperatorExpression,
				condition.operatorSymbol == "==",
				let trueExpression = ifExpression.trueExpression as? BinaryOperatorExpression,
				trueExpression.operatorSymbol == "==",
				let falseExpression = ifExpression.falseExpression as? BinaryOperatorExpression,
				falseExpression.operatorSymbol == "=="
			{
				testPassed = true
			}
			XCTAssert(testPassed, "Expected other operators to have precedence over if " +
				"expressions.\n" +
				"Range: \(String(describing: statement.range))\n" +
				"Statement:\n\(statement.prettyDescription())")

			// - Ternary expressions over assignments
			// `y = 0 == 1 ? 2 == 3 : 4 == 5`
			testPassed = false
			statement = statementIterator.next()! // Skip `var y = true`
			statement = statementIterator.next()!
			if let assignmentStatement = statement as? AssignmentStatement,
				let ifExpression =
					assignmentStatement.rightHand as? IfExpression,
				let condition = ifExpression.condition as? BinaryOperatorExpression,
				condition.operatorSymbol == "==",
				let trueExpression = ifExpression.trueExpression as? BinaryOperatorExpression,
				trueExpression.operatorSymbol == "==",
				let falseExpression = ifExpression.falseExpression as? BinaryOperatorExpression,
				falseExpression.operatorSymbol == "=="
			{
				testPassed = true
			}
			XCTAssert(testPassed, "Expected other operators to have precedence over if " +
				"expressions, which should have precedence over assignments.\n" +
				"Range: \(String(describing: statement.range))\n" +
				"Statement:\n\(statement.prettyDescription())")

			// Assert there are no remaining statements to test
			XCTAssert(
				statementIterator.next() == nil,
				"Unexpected statements that haven't been tested")
		}
		catch let error {
			XCTFail("🚨 SwiftSyntaxDecoder Test failed with error:\n\(error)")
		}
	}
}

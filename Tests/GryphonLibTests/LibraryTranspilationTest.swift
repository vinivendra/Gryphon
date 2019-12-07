//
// Copyright 2018 Vinícius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

@testable import GryphonLib
import XCTest

class LibraryTranspilationTest: XCTestCase {
	func testSimpleMatches() {
		let range1 = SourceFileRange(lineStart: 1, lineEnd: 1, columnStart: 1, columnEnd: 1)
		let range2 = SourceFileRange(lineStart: 2, lineEnd: 2, columnStart: 2, columnEnd: 2)

		let nilExpression1 = NilLiteralExpression(range: nil)
		let nilExpression2 = NilLiteralExpression(range: nil)
		let integerExpression1 = LiteralIntExpression(range: nil, value: 10)
		let integerExpression2 = LiteralIntExpression(range: nil, value: 10)
		let integerExpression3 = LiteralIntExpression(range: nil, value: 100)
		let integerExpression4 = LiteralIntExpression(range: range1, value: 100)
		let integerExpression5 = LiteralIntExpression(range: range2, value: 100)
		let parenthesesExpression1 = ParenthesesExpression(
			range: nil, expression: integerExpression1)
		let parenthesesExpression2 = ParenthesesExpression(
			range: nil, expression: integerExpression2)
		let parenthesesExpression3 = ParenthesesExpression(
			range: nil, expression: integerExpression3)
		let arrayExpression1 = ArrayExpression(
			range: nil,
			elements: [integerExpression1, integerExpression2, integerExpression3],
			typeName: "Int")
		let arrayExpression2 = ArrayExpression(
			range: nil,
			elements: [integerExpression1, integerExpression2, integerExpression3],
			typeName: "Int")
		let arrayExpression3 = ArrayExpression(
			range: nil,
			elements: [integerExpression1, integerExpression1, integerExpression1],
			typeName: "Int")
		let arrayExpression4 = ArrayExpression(
			range: nil,
			elements: [integerExpression1],
			typeName: "Int")

		// Matches itself
		XCTAssertNotNil(nilExpression1.matches(nilExpression1))
		XCTAssertNotNil(integerExpression1.matches(integerExpression1))

		// Matches something equal
		XCTAssertNotNil(nilExpression1.matches(nilExpression2))
		XCTAssertNotNil(integerExpression1.matches(integerExpression2))

		// Does not match an unrelated kind of expression
		XCTAssertNil(nilExpression1.matches(integerExpression1))

		// Does not match an expression with different contents
		XCTAssertNil(integerExpression1.matches(integerExpression3))

		// Matches work recursively
		XCTAssertNotNil(parenthesesExpression1.matches(parenthesesExpression2))
		XCTAssertNil(parenthesesExpression1.matches(parenthesesExpression3))

		// Matches work recursively on array literals
		XCTAssertNotNil(arrayExpression1.matches(arrayExpression2))
		XCTAssertNil(arrayExpression1.matches(arrayExpression3))
		XCTAssertNil(arrayExpression1.matches(arrayExpression4))

		// Matches ignore ranges
		XCTAssertNotNil(integerExpression4.matches(integerExpression5))
		XCTAssertNotNil(integerExpression3.matches(integerExpression5))
	}

	func testMatchDictionary() {
		let anyDeclarationReference = DeclarationReferenceExpression(
			range: nil,
			identifier: "_any",
			typeName: "Any",
			isStandardLibrary: false,
			isImplicit: false)
		let stringDeclarationReference = DeclarationReferenceExpression(
			range: nil,
			identifier: "_string",
			typeName: "String",
			isStandardLibrary: false,
			isImplicit: false)
		let parenthesesAnyTemplate = ParenthesesExpression(
			range: nil,
			expression: anyDeclarationReference)
		let parenthesesStringTemplate = ParenthesesExpression(
			range: nil,
			expression: stringDeclarationReference)
		let arrayTemplate = ArrayExpression(
			range: nil,
			elements: [anyDeclarationReference, stringDeclarationReference],
			typeName: "Any")

		let stringLiteral = LiteralStringExpression(
			range: nil,
			value: "foo",
			isMultiline: false)
		let integerLiteral = LiteralIntExpression(
			range: nil,
			value: 10)
		let parenthesesStringExpression = ParenthesesExpression(
			range: nil,
			expression: stringLiteral)
		let parenthesesIntegerExpression = ParenthesesExpression(
			range: nil,
			expression: integerLiteral)
		let arrayExpression = ArrayExpression(
			range: nil,
			elements: [integerLiteral, stringLiteral],
			typeName: "Any")

		// Valid subtype
		XCTAssertEqual(
			stringLiteral.matches(anyDeclarationReference),
			["_any": stringLiteral])
		XCTAssertEqual(
			stringLiteral.matches(stringDeclarationReference),
			["_string": stringLiteral])
		XCTAssertEqual(
			integerLiteral.matches(anyDeclarationReference),
			["_any": integerLiteral])

		// Invalid subtype
		XCTAssertNil(integerLiteral.matches(stringDeclarationReference))

		// Matches work recursively
		XCTAssertEqual(
			parenthesesStringExpression.matches(parenthesesAnyTemplate),
			["_any": stringLiteral])
		XCTAssertEqual(
			parenthesesStringExpression.matches(parenthesesStringTemplate),
			["_string": stringLiteral])
		XCTAssertEqual(
			parenthesesIntegerExpression.matches(parenthesesAnyTemplate),
			["_any": integerLiteral])
		XCTAssertNil(parenthesesIntegerExpression.matches(parenthesesStringTemplate))

		// Multiple matches
		XCTAssertEqual(
			arrayExpression.matches(arrayTemplate),
			["_any": integerLiteral, "_string": stringLiteral])
	}

	// MARK: - Special cases
	func testImplicitTypeExpression() {
		let implicitTypeExpression = DeclarationReferenceExpression(
			range: nil,
			identifier: "self",
			typeName: "Int.Type",
			isStandardLibrary: false,
			isImplicit: true)
		let typeExpression = TypeExpression(
			range: nil,
			typeName: "Int")

		XCTAssertNotNil(implicitTypeExpression.matches(typeExpression))
		XCTAssertNotNil(typeExpression.matches(implicitTypeExpression))
	}

	/// Templates for call expressions with trailing closures (`f { ... }`) are created using
	/// closures normally (`f(b: _closure)`), but they still have to match call expressions with
	/// trailing closures.
	func testTrailingClosures() {
		let closureExpression = ClosureExpression(
			range: nil,
			parameters: [],
			statements: [],
			typeName: "() -> ()")

		let trailingExpression = CallExpression(
			range: nil,
			function: DeclarationReferenceExpression(
				range: nil,
				identifier: "f(b:)",
				typeName: "(() -> ()) -> ()",
				isStandardLibrary: false,
				isImplicit: false),
			parameters: TupleExpression(
				range: nil,
				pairs: [LabeledExpression(
					label: nil,
					expression: ParenthesesExpression(
						range: nil,
						expression: closureExpression)),
			]),
			typeName: "Void")

		let normalExpression = CallExpression(
			range: nil,
			function: DeclarationReferenceExpression(
				range: nil,
				identifier: "f(b:)",
				typeName: "(() -> ()) -> ()",
				isStandardLibrary: false,
				isImplicit: false),
			parameters: TupleExpression(
				range: nil,
				pairs: [LabeledExpression(
					label: "b",
					expression: closureExpression),
			]),
			typeName: "Void")

		let template = CallExpression(
			range: nil,
			function: DeclarationReferenceExpression(
				range: nil,
				identifier: "f(b:)",
				typeName: "(() -> ()) -> ()",
				isStandardLibrary: false,
				isImplicit: false),
			parameters: TupleExpression(
				range: nil,
				pairs: [LabeledExpression(
					label: "b",
					expression: DeclarationReferenceExpression(
						range: nil,
						identifier: "_closure",
						typeName: "() -> ()",
						isStandardLibrary: false,
						isImplicit: false)),
			]),
			typeName: "Void")

		XCTAssertEqual(trailingExpression.matches(template), ["_closure": closureExpression])
		XCTAssertEqual(normalExpression.matches(template), ["_closure": closureExpression])
	}
}

//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license.md
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// gryphon output: Bootstrap/LibraryTranspilationTest.kt

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

class LibraryTranspilationTest: XCTestCase {
	// gryphon insert: constructor(): super() { }

	public func getClassName() -> String { // gryphon annotation: override
		return "LibraryTranspilationTest"
	}

	/// Tests to be run by the translated Kotlin version.
	public func runAllTests() { // gryphon annotation: override
		testSimpleMatches()
		testMatchDictionary()
		testImplicitTypeExpression()
		testTrailingClosures()
		testSubtyping()
		testSimplifiedSubtypes()
	}

	/// Tests to be run when using Swift on Linux
	static var allTests = [ // gryphon ignore
		("testSimpleMatches", testSimpleMatches),
		("testMatchDictionary", testMatchDictionary),
		("testImplicitTypeExpression", testImplicitTypeExpression),
		("testTrailingClosures", testTrailingClosures),
		("testSubtyping", testSubtyping),
		("testSimplifiedSubtypes", testSimplifiedSubtypes),
	]

	// MARK: - Tests
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

	// MARK: - Subtyping

	func testSubtyping() {
		// Same types
		XCTAssert("String".isSubtype(of: "String"))
		XCTAssert("Int".isSubtype(of: "Int"))
		XCTAssert("Any".isSubtype(of: "Any"))
		XCTAssert("Box<Int>".isSubtype(of: "Box<Int>"))
		XCTAssert("Dictionary<Int, String>".isSubtype(of: "Dictionary<Int, String>"))

		// Different types
		XCTAssertFalse("String".isSubtype(of: "Int"))
		XCTAssertFalse("Int".isSubtype(of: "String"))

		// Empty types
		XCTAssertFalse("".isSubtype(of: "Int"))
		XCTAssertFalse("Int".isSubtype(of: ""))

		// Universal supertypes
		XCTAssert("String".isSubtype(of: "Any"))
		XCTAssert("Int".isSubtype(of: "Any"))
		XCTAssert("Any".isSubtype(of: "Any"))
		XCTAssert("Box<Int>".isSubtype(of: "Any"))
		XCTAssert("Dictionary<Int, String>".isSubtype(of: "Any"))

		XCTAssert("String".isSubtype(of: "_Any"))
		XCTAssert("Int".isSubtype(of: "_Any"))
		XCTAssert("Any".isSubtype(of: "_Any"))
		XCTAssert("Box<Int>".isSubtype(of: "_Any"))
		XCTAssert("Dictionary<Int, String>".isSubtype(of: "_Any"))

		XCTAssert("String".isSubtype(of: "_Hashable"))
		XCTAssert("Int".isSubtype(of: "_Hashable"))
		XCTAssert("Any".isSubtype(of: "_Hashable"))
		XCTAssert("Box<Int>".isSubtype(of: "_Hashable"))
		XCTAssert("Dictionary<Int, String>".isSubtype(of: "_Hashable"))

		XCTAssert("String".isSubtype(of: "_Comparable"))
		XCTAssert("Int".isSubtype(of: "_Comparable"))
		XCTAssert("Any".isSubtype(of: "_Comparable"))
		XCTAssert("Box<Int>".isSubtype(of: "_Comparable"))
		XCTAssert("Dictionary<Int, String>".isSubtype(of: "_Comparable"))

		XCTAssert("String".isSubtype(of: "_Optional"))
		XCTAssert("Int".isSubtype(of: "_Optional"))
		XCTAssert("Any".isSubtype(of: "_Optional"))
		XCTAssert("Box<Int>".isSubtype(of: "_Optional"))
		XCTAssert("Dictionary<Int, String>".isSubtype(of: "_Optional"))

		// Optionals
		XCTAssert("String?".isSubtype(of: "_Optional?"))
		XCTAssert("Int?".isSubtype(of: "_Optional?"))
		XCTAssert("Any?".isSubtype(of: "_Optional?"))
		XCTAssert("Box<Int>?".isSubtype(of: "_Optional?"))
		XCTAssert("Dictionary<Int, String>?".isSubtype(of: "_Optional?"))

		XCTAssertFalse("String".isSubtype(of: "_Optional?"))
		XCTAssertFalse("Int".isSubtype(of: "_Optional?"))
		XCTAssertFalse("Any".isSubtype(of: "_Optional?"))
		XCTAssertFalse("Box<Int>".isSubtype(of: "_Optional?"))
		XCTAssertFalse("Dictionary<Int, String>".isSubtype(of: "_Optional?"))

		// Tuples
		XCTAssert("(String)".isSubtype(of: "(String)"))
		XCTAssert("(String)".isSubtype(of: "(Any)"))
		XCTAssertFalse("(String)".isSubtype(of: "(Int)"))

		XCTAssert("(String, Int)".isSubtype(of: "(String, Int)"))
		XCTAssert("(String, Int)".isSubtype(of: "(Any, Int)"))
		XCTAssert("(String, Int)".isSubtype(of: "(String, Any)"))
		XCTAssert("(String, Int)".isSubtype(of: "(Any, Any)"))
		XCTAssertFalse("(String, Int)".isSubtype(of: "(Int, Int)"))

		XCTAssertFalse("(String)".isSubtype(of: "(String, String)"))
		XCTAssertFalse("(String, String)".isSubtype(of: "(String)"))
		XCTAssertFalse("(String, Int)".isSubtype(of: "(Any)"))

		// Arrays
		XCTAssert("[String]".isSubtype(of: "[String]"))
		XCTAssert("[String]".isSubtype(of: "[Any]"))
		XCTAssertFalse("[String]".isSubtype(of: "[Int]"))

		// Dictionaries
		XCTAssert("[String : String]".isSubtype(of: "[String : String]"))
		XCTAssert("[String : String]".isSubtype(of: "[Any : Any]"))
		XCTAssert("[String : String]".isSubtype(of: "[String : Any]"))
		XCTAssert("[String : String]".isSubtype(of: "[Any : String]"))
		XCTAssertFalse("[String : String]".isSubtype(of: "[Int : Int]"))
		XCTAssertFalse("[String : String]".isSubtype(of: "[Int : String]"))
		XCTAssertFalse("[String : String]".isSubtype(of: "[String : Int]"))

		// Generics
		XCTAssert("Box<String>".isSubtype(of: "Box<Any>"))
		XCTAssertFalse("Box<String>".isSubtype(of: "Box<Int>"))
		// XCTAssertFalse("Box<String>".isSubtype(of: "Foo<String>"))

		XCTAssert("Box<String, String>".isSubtype(of: "Box<Any, Any>"))
		XCTAssert("Box<String, String>".isSubtype(of: "Box<Any, String>"))
		XCTAssert("Box<String, String>".isSubtype(of: "Box<String, Any>"))
		XCTAssertFalse("Box<String, String>".isSubtype(of: "Box<Any>"))
		XCTAssertFalse("Box<String, String>".isSubtype(of: "Box<Int, String>"))
		XCTAssertFalse("Box<String, String>".isSubtype(of: "Box<String, Int>"))
		// XCTAssertFalse("Box<String, String>".isSubtype(of: "Foo<String, String>"))
	}

	func testSimplifiedSubtypes() {
		// Mapped types
		XCTAssert("Bool".isSubtype(of: "Boolean"))
		XCTAssert("Boolean".isSubtype(of: "Bool"))

		// Arrays
		XCTAssert("MutableList<Int>".isSubtype(of: "[Int]"))
		XCTAssert("[Int]".isSubtype(of: "MutableList<Int>"))
		XCTAssert("List<Int>".isSubtype(of: "[Int]"))
		XCTAssert("[Int]".isSubtype(of: "List<Int>"))
		// XCTAssert("Array<Int>".isSubtype(of: "[Int]"))
		// XCTAssert("[Int]".isSubtype(of: "Array<Int>"))

		// Dictionaries
		XCTAssert("MutableMap<Int, Int>".isSubtype(of: "[Int : Int]"))
		XCTAssert("[Int : Int]".isSubtype(of: "MutableMap<Int, Int>"))
		XCTAssert("Map<Int, Int>".isSubtype(of: "[Int : Int]"))
		XCTAssert("[Int : Int]".isSubtype(of: "Map<Int, Int>"))
		// XCTAssert("Dictionary<Int, Int>".isSubtype(of: "[Int : Int]"))
		// XCTAssert("[Int : Int]".isSubtype(of: "Dictionary<Int, Int>"))

		// Array slices
		XCTAssert("Slice<MutableList<Int>>".isSubtype(of: "[Int]"))
		XCTAssert("[Int]".isSubtype(of: "Slice<MutableList<Int>>"))
		// XCTAssert("Slice<List<Int>>".isSubtype(of: "[Int]"))
		// XCTAssert("[Int]".isSubtype(of: "Slice<List<Int>>"))
		// XCTAssert("Slice<Array<Int>>".isSubtype(of: "[Int]"))
		// XCTAssert("[Int]".isSubtype(of: "Slice<Array<Int>>"))

		// Parentheses
		XCTAssert("(Int)".isSubtype(of: "Int"))
		XCTAssert("Int".isSubtype(of: "(Int)"))

		// Keywords
		XCTAssert("inout Int".isSubtype(of: "Int"))
		XCTAssert("Int".isSubtype(of: "inout Int"))

		XCTAssert("__owned Int".isSubtype(of: "Int"))
		XCTAssert("Int".isSubtype(of: "__owned Int"))
	}
}

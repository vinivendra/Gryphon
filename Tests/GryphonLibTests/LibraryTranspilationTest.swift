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

@testable import GryphonLib
import XCTest

class LibraryTranspilationTest: XCTestCase {
	/// Tests to be run when using Swift on Linux
	static var allTests = [
		("testSimpleMatches", testSimpleMatches),
		("testMatchDictionary", testMatchDictionary),
		("testImplicitTypeExpression", testImplicitTypeExpression),
		("testTrailingClosures", testTrailingClosures),
		("testSubtyping", testSubtyping),
		("testSimplifiedSubtypes", testSimplifiedSubtypes),
	]

	// MARK: - Properties
	/// Mock transpilation pass used for checking matches.
	let pass = ReplaceTemplatesTranspilationPass(
		ast: GryphonAST(
			sourceFile: nil, declarations: [], statements: [], outputFileMap: [:],
			indexingResponse: [:]),
		context: try! TranspilationContext(
			indentationString: "\t",
			defaultsToFinal: false,
			compilationArguments: TranspilationContext.SwiftCompilationArguments(
				absoluteFilePathsAndOtherArguments: []),
			xcodeProjectPath: nil,
			target: nil))

	// MARK: - Tests
	func testSimpleMatches() {
		let range1 = SourceFileRange(lineStart: 1, lineEnd: 1, columnStart: 1, columnEnd: 1)
		let range2 = SourceFileRange(lineStart: 2, lineEnd: 2, columnStart: 2, columnEnd: 2)

		let nilExpression1 = NilLiteralExpression(range: nil)
		let nilExpression2 = NilLiteralExpression(range: nil)
		let integerExpression1 = LiteralIntExpression(range: nil, value: 10, radix: .decimal)
		let integerExpression2 = LiteralIntExpression(range: nil, value: 10, radix: .decimal)
		let integerExpression3 = LiteralIntExpression(range: nil, value: 100, radix: .decimal)
		let integerExpression4 = LiteralIntExpression(range: range1, value: 100, radix: .decimal)
		let integerExpression5 = LiteralIntExpression(range: range2, value: 100, radix: .decimal)
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
		XCTAssertNotNil(pass.matchExpression(
			nilExpression1,
			withTemplate: nilExpression1,
			shouldSkipRootTypeComparison: false))
		XCTAssertNotNil(pass.matchExpression(
			integerExpression1,
			withTemplate: integerExpression1,
			shouldSkipRootTypeComparison: false))

		// Matches something equal
		XCTAssertNotNil(pass.matchExpression(
			nilExpression1,
			withTemplate: nilExpression2,
			shouldSkipRootTypeComparison: false))
		XCTAssertNotNil(pass.matchExpression(
			integerExpression1,
			withTemplate: integerExpression2,
			shouldSkipRootTypeComparison: false))

		// Does not match an unrelated kind of expression
		XCTAssertNil(pass.matchExpression(
			nilExpression1,
			withTemplate: integerExpression1,
			shouldSkipRootTypeComparison: false))

		// Does not match an expression with different contents
		XCTAssertNil(pass.matchExpression(
			integerExpression1,
			withTemplate: integerExpression3,
			shouldSkipRootTypeComparison: false))

		// Matches work recursively
		XCTAssertNotNil(pass.matchExpression(
			parenthesesExpression1,
			withTemplate: parenthesesExpression2,
			shouldSkipRootTypeComparison: false))
		XCTAssertNil(pass.matchExpression(
			parenthesesExpression1,
			withTemplate: parenthesesExpression3,
			shouldSkipRootTypeComparison: false))

		// Matches work recursively on array literals
		XCTAssertNotNil(pass.matchExpression(
			arrayExpression1,
			withTemplate: arrayExpression2,
			shouldSkipRootTypeComparison: false))
		XCTAssertNil(pass.matchExpression(
			arrayExpression1,
			withTemplate: arrayExpression3,
			shouldSkipRootTypeComparison: false))
		XCTAssertNil(pass.matchExpression(
			arrayExpression1,
			withTemplate: arrayExpression4,
			shouldSkipRootTypeComparison: false))

		// Matches ignore ranges
		XCTAssertNotNil(pass.matchExpression(
			integerExpression4,
			withTemplate: integerExpression5,
			shouldSkipRootTypeComparison: false))
		XCTAssertNotNil(pass.matchExpression(
			integerExpression3,
			withTemplate: integerExpression5,
			shouldSkipRootTypeComparison: false))
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
			value: 10,
			radix: .decimal)
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
		XCTAssertEqual(pass.matchExpression(
				stringLiteral,
				withTemplate: anyDeclarationReference,
				shouldSkipRootTypeComparison: false),
			["_any": stringLiteral])
		XCTAssertEqual(pass.matchExpression(
				stringLiteral,
				withTemplate: stringDeclarationReference,
				shouldSkipRootTypeComparison: false),
			["_string": stringLiteral])
		XCTAssertEqual(pass.matchExpression(
			integerLiteral,
			withTemplate: anyDeclarationReference,
				shouldSkipRootTypeComparison: false),
			["_any": integerLiteral])

		// Invalid subtype
		XCTAssertNil(pass.matchExpression(
			integerLiteral,
			withTemplate: stringDeclarationReference,
			shouldSkipRootTypeComparison: false))

		// Matches work recursively
		XCTAssertEqual(
			pass.matchExpression(
				parenthesesStringExpression,
				withTemplate: parenthesesAnyTemplate,
				shouldSkipRootTypeComparison: false),
			["_any": stringLiteral])
		XCTAssertEqual(
			pass.matchExpression(
				parenthesesStringExpression,
				withTemplate: parenthesesStringTemplate,
				shouldSkipRootTypeComparison: false),
			["_string": stringLiteral])
		XCTAssertEqual(
			pass.matchExpression(
				parenthesesIntegerExpression,
				withTemplate: parenthesesAnyTemplate,
				shouldSkipRootTypeComparison: false),
			["_any": integerLiteral])
		XCTAssertNil(pass.matchExpression(
			parenthesesIntegerExpression,
			withTemplate: parenthesesStringTemplate,
			shouldSkipRootTypeComparison: false))

		// Multiple matches
		XCTAssertEqual(pass.matchExpression(
				arrayExpression,
				withTemplate: arrayTemplate,
				shouldSkipRootTypeComparison: false),
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

		XCTAssertNotNil(pass.matchExpression(
			implicitTypeExpression,
			withTemplate: typeExpression,
			shouldSkipRootTypeComparison: false))
		XCTAssertNotNil(pass.matchExpression(
			typeExpression,
			withTemplate: implicitTypeExpression,
			shouldSkipRootTypeComparison: false))
	}

	/// Templates for call expressions with trailing closures (`f { ... }`) are created using
	/// closures normally (`f(b: _closure)`), but they still have to match call expressions with
	/// trailing closures.
	func testTrailingClosures() {
		let trailingClosureExpression = ClosureExpression(
			range: nil,
			parameters: [],
			statements: [],
			typeName: "() -> ()",
			isTrailing: true)
		let nonTrailingClosureExpression = ClosureExpression(
			range: nil,
			parameters: [],
			statements: [],
			typeName: "() -> ()",
			isTrailing: false)

		let trailingCallExpression = CallExpression(
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
						expression: trailingClosureExpression)),
			]),
			typeName: "Void",
			allowsTrailingClosure: true,
			isPure: true)

		let nonTrailingCallExpression = CallExpression(
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
					expression: nonTrailingClosureExpression),
			]),
			typeName: "Void",
			allowsTrailingClosure: true,
			isPure: true)

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
			typeName: "Void",
			allowsTrailingClosure: true,
			isPure: true)

		XCTAssertEqual(pass.matchExpression(
				trailingCallExpression,
				withTemplate: template,
				shouldSkipRootTypeComparison: false),
			["_closure": trailingClosureExpression])
		XCTAssertEqual(pass.matchExpression(
				nonTrailingCallExpression,
				withTemplate: template,
				shouldSkipRootTypeComparison: false),
			["_closure": nonTrailingClosureExpression])
	}

	// MARK: - Subtyping

	func testSubtyping() {
		let context = pass.context

		// Same types
		XCTAssert(context.isSubtype("String", of: "String"))
		XCTAssert(context.isSubtype("Int", of: "Int"))
		XCTAssert(context.isSubtype("Any", of: "Any"))
		XCTAssert(context.isSubtype("Box<Int>", of: "Box<Int>"))
		XCTAssert(context.isSubtype("Dictionary<Int, String>", of: "Dictionary<Int, String>"))

		// Different types
		XCTAssertFalse(context.isSubtype("String", of: "Int"))
		XCTAssertFalse(context.isSubtype("Int", of: "String"))

		// Empty types
		XCTAssertFalse(context.isSubtype("", of: "Int"))
		XCTAssertFalse(context.isSubtype("Int", of: ""))

		// Universal supertypes
		XCTAssert(context.isSubtype("String", of: "Any"))
		XCTAssert(context.isSubtype("Int", of: "Any"))
		XCTAssert(context.isSubtype("Any", of: "Any"))
		XCTAssert(context.isSubtype("Box<Int>", of: "Any"))
		XCTAssert(context.isSubtype("Dictionary<Int, String>", of: "Any"))

		XCTAssert(context.isSubtype("String", of: "_Any"))
		XCTAssert(context.isSubtype("Int", of: "_Any"))
		XCTAssert(context.isSubtype("Any", of: "_Any"))
		XCTAssert(context.isSubtype("Box<Int>", of: "_Any"))
		XCTAssert(context.isSubtype("Dictionary<Int, String>", of: "_Any"))

		XCTAssert(context.isSubtype("String", of: "_Hashable"))
		XCTAssert(context.isSubtype("Int", of: "_Hashable"))
		XCTAssert(context.isSubtype("Any", of: "_Hashable"))
		XCTAssert(context.isSubtype("Box<Int>", of: "_Hashable"))
		XCTAssert(context.isSubtype("Dictionary<Int, String>", of: "_Hashable"))

		XCTAssert(context.isSubtype("String", of: "_Comparable"))
		XCTAssert(context.isSubtype("Int", of: "_Comparable"))
		XCTAssert(context.isSubtype("Any", of: "_Comparable"))
		XCTAssert(context.isSubtype("Box<Int>", of: "_Comparable"))
		XCTAssert(context.isSubtype("Dictionary<Int, String>", of: "_Comparable"))

		XCTAssert(context.isSubtype("String", of: "_Optional"))
		XCTAssert(context.isSubtype("Int", of: "_Optional"))
		XCTAssert(context.isSubtype("Any", of: "_Optional"))
		XCTAssert(context.isSubtype("Box<Int>", of: "_Optional"))
		XCTAssert(context.isSubtype("Dictionary<Int, String>", of: "_Optional"))

		// Optionals
		XCTAssert(context.isSubtype("String?", of: "_Optional?"))
		XCTAssert(context.isSubtype("Int?", of: "_Optional?"))
		XCTAssert(context.isSubtype("Any?", of: "_Optional?"))
		XCTAssert(context.isSubtype("Box<Int>?", of: "_Optional?"))
		XCTAssert(context.isSubtype("Dictionary<Int, String>?", of: "_Optional?"))

		XCTAssertFalse(context.isSubtype("String", of: "_Optional?"))
		XCTAssertFalse(context.isSubtype("Int", of: "_Optional?"))
		XCTAssertFalse(context.isSubtype("Any", of: "_Optional?"))
		XCTAssertFalse(context.isSubtype("Box<Int>", of: "_Optional?"))
		XCTAssertFalse(context.isSubtype("Dictionary<Int, String>", of: "_Optional?"))

		// Tuples
		XCTAssert(context.isSubtype("(String)", of: "(String)"))
		XCTAssert(context.isSubtype("(String)", of: "(Any)"))
		XCTAssertFalse(context.isSubtype("(String)", of: "(Int)"))

		XCTAssert(context.isSubtype("(String, Int)", of: "(String, Int)"))
		XCTAssert(context.isSubtype("(String, Int)", of: "(Any, Int)"))
		XCTAssert(context.isSubtype("(String, Int)", of: "(String, Any)"))
		XCTAssert(context.isSubtype("(String, Int)", of: "(Any, Any)"))
		XCTAssertFalse(context.isSubtype("(String, Int)", of: "(Int, Int)"))

		XCTAssertFalse(context.isSubtype("(String)", of: "(String, String)"))
		XCTAssertFalse(context.isSubtype("(String, String)", of: "(String)"))
		XCTAssertFalse(context.isSubtype("(String, Int)", of: "(Any)"))

		// Arrays
		XCTAssert(context.isSubtype("[String]", of: "[String]"))
		XCTAssert(context.isSubtype("[String]", of: "[Any]"))
		XCTAssertFalse(context.isSubtype("[String]", of: "[Int]"))

		// Dictionaries
		XCTAssert(context.isSubtype("[String : String]", of: "[String : String]"))
		XCTAssert(context.isSubtype("[String : String]", of: "[Any : Any]"))
		XCTAssert(context.isSubtype("[String : String]", of: "[String : Any]"))
		XCTAssert(context.isSubtype("[String : String]", of: "[Any : String]"))
		XCTAssertFalse(context.isSubtype("[String : String]", of: "[Int : Int]"))
		XCTAssertFalse(context.isSubtype("[String : String]", of: "[Int : String]"))
		XCTAssertFalse(context.isSubtype("[String : String]", of: "[String : Int]"))

		// Generics
		XCTAssert(context.isSubtype("Box<String>", of: "Box<Any>"))
		XCTAssertFalse(context.isSubtype("Box<String>", of: "Box<Int>"))
		// XCTAssertFalse(context.isSubtype("Box<String>", of: "Foo<String>"))

		XCTAssert(context.isSubtype("Box<String, String>", of: "Box<Any, Any>"))
		XCTAssert(context.isSubtype("Box<String, String>", of: "Box<Any, String>"))
		XCTAssert(context.isSubtype("Box<String, String>", of: "Box<String, Any>"))
		XCTAssertFalse(context.isSubtype("Box<String, String>", of: "Box<Any>"))
		XCTAssertFalse(context.isSubtype("Box<String, String>", of: "Box<Int, String>"))
		XCTAssertFalse(context.isSubtype("Box<String, String>", of: "Box<String, Int>"))
		// XCTAssertFalse(context.isSubtype("Box<String, String>", of: "Foo<String, String>"))
	}

	func testSimplifiedSubtypes() {
		let context = pass.context

		// Mapped types
		XCTAssert(context.isSubtype("Bool", of: "Boolean"))
		XCTAssert(context.isSubtype("Boolean", of: "Bool"))

		// Arrays
		XCTAssert(context.isSubtype("MutableList<Int>", of: "[Int]"))
		XCTAssert(context.isSubtype("[Int]", of: "MutableList<Int>"))
		XCTAssert(context.isSubtype("List<Int>", of: "[Int]"))
		XCTAssert(context.isSubtype("[Int]", of: "List<Int>"))
		// XCTAssert(context.isSubtype("Array<Int>", of: "[Int]"))
		// XCTAssert(context.isSubtype("[Int]", of: "Array<Int>"))

		// Dictionaries
		XCTAssert(context.isSubtype("MutableMap<Int, Int>", of: "[Int : Int]"))
		XCTAssert(context.isSubtype("[Int : Int]", of: "MutableMap<Int, Int>"))
		XCTAssert(context.isSubtype("Map<Int, Int>", of: "[Int : Int]"))
		XCTAssert(context.isSubtype("[Int : Int]", of: "Map<Int, Int>"))
		// XCTAssert(context.isSubtype("Dictionary<Int, Int>", of: "[Int : Int]"))
		// XCTAssert(context.isSubtype("[Int : Int]", of: "Dictionary<Int, Int>"))

		// Array slices
		XCTAssert(context.isSubtype("Slice<MutableList<Int>>", of: "[Int]"))
		XCTAssert(context.isSubtype("[Int]", of: "Slice<MutableList<Int>>"))
		// XCTAssert(context.isSubtype("Slice<List<Int>>", of: "[Int]"))
		// XCTAssert(context.isSubtype("[Int]", of: "Slice<List<Int>>"))
		// XCTAssert(context.isSubtype("Slice<Array<Int>>", of: "[Int]"))
		// XCTAssert(context.isSubtype("[Int]", of: "Slice<Array<Int>>"))

		// Parentheses
		XCTAssert(context.isSubtype("(Int)", of: "Int"))
		XCTAssert(context.isSubtype("Int", of: "(Int)"))

		// Keywords
		XCTAssert(context.isSubtype("inout Int", of: "Int"))
		XCTAssert(context.isSubtype("Int", of: "inout Int"))

		XCTAssert(context.isSubtype("__owned Int", of: "Int"))
		XCTAssert(context.isSubtype("Int", of: "__owned Int"))
	}
}

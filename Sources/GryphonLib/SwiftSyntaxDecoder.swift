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

// gryphon output: Sources/GryphonLib/SwiftSyntaxDecoder.swiftAST
// gryphon output: Sources/GryphonLib/SwiftSyntaxDecoder.gryphonASTRaw
// gryphon output: Sources/GryphonLib/SwiftSyntaxDecoder.gryphonAST
// gryphon output: Bootstrap/SwiftSyntaxDecoder.kt

import Foundation
import SwiftSyntax
import SourceKittenFramework

public class SwiftSyntaxDecoder: SyntaxVisitor {
	let filePath: String
	let syntaxTree: SourceFileSyntax
	let expressionTypes: List<ExpressionType>

	init(filePath: String) {
		// Call SourceKitten to get the types
		// TODO: Improve this yaml. SDK paths? Absolute/relative file paths?
		let yaml = """
		{
		  key.request: source.request.expression.type,
		  key.compilerargs: [
			"\(filePath)",
			"-sdk",
			"/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk"
		  ],
		  key.sourcefile: "\(filePath)"
		}
		"""
		let request = Request.yamlRequest(yaml: yaml)
		let result = try! request.send()

		let list = result["key.expression_type_list"] as! [[String: SourceKitRepresentable]]
		let typeList = List(list.map {
			ExpressionType(
				offset: Int($0["key.expression_offset"]! as! Int64),
				length: Int($0["key.expression_length"]! as! Int64),
				typeName: $0["key.expression_type"]! as! String)
		})

		// Call SwiftSyntax to get the tree
		let tree = try! SyntaxParser.parse(URL(fileURLWithPath: filePath))

		// Initialize the properties
		self.filePath = filePath
		self.expressionTypes = typeList
		self.syntaxTree = tree
	}

	struct ExpressionType {
		let offset: Int
		let length: Int
		let typeName: String
	}

	func convertToGryphonAST() throws -> GryphonAST {
		let statements: MutableList<Statement> = []

		for statement in self.syntaxTree.statements {
			let codeBlockItemSyntax: CodeBlockItemSyntax = statement
			let item: Syntax = codeBlockItemSyntax.item

			if let declaration = item.as(DeclSyntax.self) {
				try statements.append(contentsOf: convertDeclaration(declaration))
			}
		}

		return GryphonAST(
			sourceFile: nil,
			declarations: [],
			statements: statements,
			outputFileMap: [:])
	}

	func convertDeclaration(_ declaration: DeclSyntax) throws -> MutableList<Statement> {
		if let declaration = declaration.as(VariableDeclSyntax.self) {
			return try convertVariableDeclaration(declaration)
				.forceCast(to: MutableList<Statement>.self)
		}
		throw GryphonError(errorMessage: "Failed to convert declaration \(declaration)")
	}

	func convertVariableDeclaration(
		_ variableDeclaration: VariableDeclSyntax)
		throws -> MutableList<VariableDeclaration>
	{
		let isLet = (variableDeclaration.letOrVarKeyword.text == "let")

		let result: MutableList<VariableDeclaration> = []

		let patternBindingList: PatternBindingListSyntax = variableDeclaration.bindings
		for patternBinding in patternBindingList {
			let pattern: PatternSyntax = patternBinding.pattern

			if let identifier = pattern.getText() {
				// TODO: get teh type from SourceKit if there's no annotation
				let annotatedType = patternBinding.typeAnnotation?.type.getText() ?? ""

				let expression: Expression?
				if let exprSyntax = patternBinding.initializer?.value {
					expression = try convertExpression(exprSyntax)
				}
				else {
					expression = nil
				}

				result.append(VariableDeclaration(
					range: SourceFileRange(variableDeclaration),
					identifier: identifier,
					typeName: annotatedType,
					expression: expression,
					getter: nil,
					setter: nil,
					access: nil,
					isOpen: true,
					isLet: isLet,
					isImplicit: false,
					isStatic: false,
					extendsType: nil,
					annotations: []))
			}
			else {
				throw GryphonError(
					errorMessage: "Failed to convert variable declaration: unknown pattern " +
					"binding.")
			}
		}

		return result
	}

	func convertExpression(_ expression: ExprSyntax) throws -> Expression {
		if let stringLiteralExpression = expression.as(StringLiteralExprSyntax.self) {
			return try convertStringLiteralExpression(stringLiteralExpression)
		}
		if let integerLiteralExpression = expression.as(IntegerLiteralExprSyntax.self) {
			return try convertIntegerLiteralExpression(integerLiteralExpression)
		}

		throw GryphonError(errorMessage: "Failed to convert expression: \(expression)")
	}

	func convertIntegerLiteralExpression(
		_ integerLiteralExpression: IntegerLiteralExprSyntax)
		throws -> Expression
	{
		if let intString = integerLiteralExpression.digits.getText(),
			let intValue = Int64(intString)
		{
			return LiteralIntExpression(
				range: SourceFileRange(integerLiteralExpression),
				value: intValue)
		}

		throw GryphonError(errorMessage: "Failed to convert integer literal expression: " +
			"\(integerLiteralExpression)")
	}

	func convertStringLiteralExpression(
		_ stringLiteralExpression: StringLiteralExprSyntax)
		throws -> Expression
	{
		for segment in stringLiteralExpression.segments {
			if let text = segment.getText() {
				return LiteralStringExpression(
					range: SourceFileRange(stringLiteralExpression),
					value: text,
					isMultiline: false)
			}
		}

		throw GryphonError(
			errorMessage: "Failed to convert string literal expression: \(stringLiteralExpression)")
	}
}

// Source File
// ├─ Declarations
// └─ Statements
//    └─ VariableDeclaration
//       ├─ let
//       ├─ a
//       ├─ Any
//       ├─ LiteralStringExpression
//       │  └─
//       ├─ internal
//       └─ open: false

extension SyntaxProtocol {
	func getText() -> String? {
		if let firstChild = self.children.first,
			let childTokenSyntax = firstChild.as(TokenSyntax.self)
		{
			return childTokenSyntax.text
		}
		else if let tokenSyntax = self as? TokenSyntax {
			return tokenSyntax.text
		}

		return nil
	}
}

extension SourceFileRange {
	// TODO: Implement this init so it creates a correct range (or refactor the data structure, etc)
	init<SyntaxType: SyntaxProtocol>(_ syntax: SyntaxType) {
		let position = syntax.positionAfterSkippingLeadingTrivia.utf8Offset
		let length = syntax.contentLength.utf8Length
		self.init(
			lineStart: position,
			lineEnd: position + length,
			columnStart: 1,
			columnEnd: 1)
	}
}

private extension SyntaxProtocol {
	func getType(fromList list: [SwiftSyntaxDecoder.ExpressionType]) -> String? {
		for expressionType in list {
			if self.positionAfterSkippingLeadingTrivia.utf8Offset == expressionType.offset,
				self.contentLength.utf8Length == expressionType.length
			{
				return expressionType.typeName
			}
		}

		return nil
	}
}

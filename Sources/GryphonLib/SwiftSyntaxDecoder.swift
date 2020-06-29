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
		let absolutePath = Utilities.getAbsoultePath(forFile: filePath)
		let yaml = """
		{
		  key.request: source.request.expression.type,
		  key.compilerargs: [
			"\(absolutePath)",
			"-sdk",
			"/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk"
		  ],
		  key.sourcefile: "\(absolutePath)"
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
			else if let expression = item.as(ExprSyntax.self) {
				if shouldConvertToStatement(expression) {
					try statements.append(convertExpressionToStatement(expression))
				}
				else {
					try statements.append(ExpressionStatement(
						range: SourceFileRange(expression),
						expression: convertExpression(expression)))
				}
			}
			else {
				throw GryphonError(errorMessage: "Failed to convert statement \(statement)")
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
		let annotations: MutableList<String> = MutableList(variableDeclaration.modifiers?.compactMap {
			return $0.getText()
		} ?? [])

		let result: MutableList<VariableDeclaration> = []

		let patternBindingList: PatternBindingListSyntax = variableDeclaration.bindings
		for patternBinding in patternBindingList {
			let pattern: PatternSyntax = patternBinding.pattern

			if let identifier = pattern.getText() {
				let expression: Expression?
				if let exprSyntax = patternBinding.initializer?.value {
					expression = try convertExpression(exprSyntax)
				}
				else {
					expression = nil
				}


				let annotatedType: String?
				if let typeAnnotation = patternBinding.typeAnnotation?.type {
					annotatedType = try convertType(typeAnnotation)
				}
				else  {
					annotatedType = expression?.swiftType
				}

				result.append(VariableDeclaration(
					range: SourceFileRange(variableDeclaration),
					identifier: identifier,
					typeAnnotation: annotatedType,
					expression: expression,
					getter: nil,
					setter: nil,
					access: nil,
					isOpen: true,
					isLet: isLet,
					isImplicit: false,
					isStatic: false,
					extendsType: nil,
					annotations: annotations))
			}
			else {
				throw GryphonError(
					errorMessage: "Failed to convert variable declaration: unknown pattern " +
					"binding.")
			}
		}

		return result
	}

	func shouldConvertToStatement(_ expression: ExprSyntax) -> Bool {
		if expression.is(SequenceExprSyntax.self) {
			return true
		}

		return false
	}

	func convertExpressionToStatement(_ expression: ExprSyntax) throws -> Statement {
		if let sequenceExpression = expression.as(SequenceExprSyntax.self) {
			return try convertSequenceExpression(sequenceExpression)
		}

		throw GryphonError(errorMessage: "Failed to convert expression to statement: \(expression)")
	}

	func convertSequenceExpression(
		_ sequenceExpression: SequenceExprSyntax)
		throws -> Statement
	{
		let expressionList = List(sequenceExpression.elements)

		if expressionList.count == 3,
			expressionList[1].is(AssignmentExprSyntax.self),
			let leftExpression = expressionList[0].as(ExprSyntax.self),
			let rightExpression = expressionList[2].as(ExprSyntax.self)
		{
			let translatedLeftExpression = try convertExpression(leftExpression)
			let translatedRightExpression = try convertExpression(rightExpression)
			return AssignmentStatement(
				range: SourceFileRange(sequenceExpression),
				leftHand: translatedLeftExpression,
				rightHand: translatedRightExpression)
		}

		throw GryphonError(errorMessage: "Failed to convert sequence expression: " +
			"\(sequenceExpression)")
	}

	func convertExpression(_ expression: ExprSyntax) throws -> Expression {
		if let stringLiteralExpression = expression.as(StringLiteralExprSyntax.self) {
			return try convertStringLiteralExpression(stringLiteralExpression)
		}
		if let integerLiteralExpression = expression.as(IntegerLiteralExprSyntax.self) {
			return try convertIntegerLiteralExpression(integerLiteralExpression)
		}
		if let identifierExpression = expression.as(IdentifierExprSyntax.self) {
			return try convertIdentifierExpression(identifierExpression)
		}
		if let functionCallExpression = expression.as(FunctionCallExprSyntax.self) {
			return try convertFunctionCallExpression(functionCallExpression)
		}
		if let nilLiteralExpression = expression.as(NilLiteralExprSyntax.self) {
			return try convertNilLiteralExpression(nilLiteralExpression)
		}

		throw GryphonError(errorMessage: "Failed to convert expression: \(expression)")
	}

	func convertNilLiteralExpression(
		_ nilLiteralExpression: NilLiteralExprSyntax)
		throws -> Expression
	{
		return NilLiteralExpression(range: SourceFileRange(nilLiteralExpression))
	}

	func convertFunctionCallExpression(
		_ functionCallExpression: FunctionCallExprSyntax)
		throws -> Expression
	{
		let children = List(functionCallExpression.children)

		// `function` + `(` + `tupleExpressionElements` + `)`
		if children.count == 4,
			let functionExpression = children[0].as(ExprSyntax.self),
			children[1].is(TokenSyntax.self),
			let tupleExpressionElements = children[2].as(TupleExprElementListSyntax.self),
			children[3].is(TokenSyntax.self)
		{
			let functionExpressionTranslation = try convertExpression(functionExpression)
			let tupleExpression = try convertTupleExpressionElementList(tupleExpressionElements)
			return CallExpression(
				range: SourceFileRange(functionCallExpression),
				function: functionExpressionTranslation,
				parameters: tupleExpression,
				typeName: functionCallExpression.getType(fromList: self.expressionTypes))
		}

		return NilLiteralExpression(range: nil)
	}

	/// The `convertFunctionCallExpression` method assumes this returns something that can be put in
	/// a `CallExpression`, like a `TupleExpression` or a `TupleShuffleExpression`.
	func convertTupleExpressionElementList(
		_ tupleExprElementListSyntax: TupleExprElementListSyntax)
		throws -> Expression
	{
		let elements = List(tupleExprElementListSyntax)
		let pairs: MutableList<LabeledExpression> = []

		for tupleExpressionElement in elements {
			let label = tupleExpressionElement.label?.text
			let translatedExpression = try convertExpression(tupleExpressionElement.expression)
			pairs.append(LabeledExpression(label: label, expression: translatedExpression))
		}

		return TupleExpression(
			range: SourceFileRange(tupleExprElementListSyntax),
			pairs: pairs)
	}

	func convertIdentifierExpression(
		_ identifierExpression: IdentifierExprSyntax)
		throws -> Expression
	{
		// TODO: DeclRef should have optional type
		return DeclarationReferenceExpression(
			range: SourceFileRange(identifierExpression),
			identifier: identifierExpression.identifier.text,
			typeName: identifierExpression.getType(fromList: self.expressionTypes) ?? "",
			isStandardLibrary: false,
			isImplicit: false)
	}

	func convertIntegerLiteralExpression(
		_ integerLiteralExpression: IntegerLiteralExprSyntax)
		throws -> Expression
	{
		if let intValue = Int64(integerLiteralExpression.digits.text) {
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
		let range = SourceFileRange(stringLiteralExpression)

		// If it's a string literal
		if stringLiteralExpression.segments.count == 1,
			let text = stringLiteralExpression.segments.first!.getText()
		{
			return LiteralStringExpression(
				range: range,
				value: text,
				isMultiline: false)
		}

		// If it's a string interpolation
		let expressions: MutableList<Expression> = []
		for segment in stringLiteralExpression.segments {
			if let stringSegment = segment.as(StringSegmentSyntax.self),
				let text = stringSegment.getText()
			{
				expressions.append(LiteralStringExpression(
					range: SourceFileRange(stringSegment),
					value: text,
					isMultiline: false))
				continue
			}

			// `\` + `(` + `expression` + `)`
			// The expression comes enveloped in a tuple
			if let expressionSegment = segment.as(ExpressionSegmentSyntax.self) {
				let children = List(expressionSegment.children)
				if children.count == 4,
					children[0].is(TokenSyntax.self),
					children[1].is(TokenSyntax.self),
					let tupleExpressionElements = children[2].as(TupleExprElementListSyntax.self),
					children[3].is(TokenSyntax.self),
					tupleExpressionElements.count == 1,
					let onlyTupleElement = tupleExpressionElements.first,
					onlyTupleElement.label == nil
				{
					try expressions.append(convertExpression(onlyTupleElement.expression))
					continue
				}
			}

			throw GryphonError(errorMessage: "Unrecognized expression in string literal " +
				"interpolation: \(stringLiteralExpression)")
		}

		return InterpolatedStringLiteralExpression(
			range: range,
			expressions: expressions)
	}

	func convertType(_ typeSyntax: TypeSyntax) throws -> String {
		if let text = typeSyntax.getText() {
			return text
		}
		if let optionalType = typeSyntax.as(OptionalTypeSyntax.self) {
			return try convertType(optionalType.wrappedType) + "?"
		}

		throw GryphonError(errorMessage: "Unknown type: \(typeSyntax)")
	}
}

extension SyntaxProtocol {
	func getText() -> String? {
		if let firstChild = self.children.first,
			let childTokenSyntax = firstChild.as(TokenSyntax.self)
		{
			return childTokenSyntax.text
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
	func getType(fromList list: List<SwiftSyntaxDecoder.ExpressionType>) -> String? {
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

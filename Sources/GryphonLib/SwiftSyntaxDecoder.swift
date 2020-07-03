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
	/// The source file to be translated
	let sourceFile: SourceFile
	/// The tree to be translated, obtained from SwiftSyntax
	let syntaxTree: SourceFileSyntax
	/// A list of types associated with source ranges, obtained from SourceKit
	let expressionTypes: List<ExpressionType>
	/// The map that relates each type of output to the path to the file in which to write that
	/// output
	var outputFileMap: MutableMap<FileExtension, String> = [:]

	init(filePath: String) throws {
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
		let tree = try SyntaxParser.parse(URL(fileURLWithPath: filePath))

		// Initialize the properties
		// TODO: Check if these file readings aren't redundant
		self.sourceFile = try SourceFile(path: filePath, contents: Utilities.readFile(filePath))
		self.expressionTypes = typeList
		self.syntaxTree = tree
	}

	struct ExpressionType {
		let offset: Int
		let length: Int
		let typeName: String
	}

	func convertToGryphonAST(asMainFile isMainFile: Bool) throws -> GryphonAST {
		let statements = try convertStatements(self.syntaxTree.statements)

		if isMainFile {
			let declarationsAndStatements = filterStatements(statements)

			return GryphonAST(
				sourceFile: self.sourceFile,
				declarations: declarationsAndStatements.0,
				statements: declarationsAndStatements.1,
				outputFileMap: self.outputFileMap)
		}
		else {
			return GryphonAST(
				sourceFile: self.sourceFile,
				declarations: statements,
				statements: [],
				outputFileMap: self.outputFileMap)
		}
	}

	func convertStatements(_ statements: CodeBlockItemListSyntax) throws -> MutableList<Statement> {
		let result: MutableList<Statement> = []

		for statement in statements {
			let codeBlockItemSyntax: CodeBlockItemSyntax = statement
			let item: Syntax = codeBlockItemSyntax.item

			if let declaration = item.as(DeclSyntax.self) {
				try result.append(contentsOf: convertDeclaration(declaration))
			}
			else if let statement = item.as(StmtSyntax.self) {
				try result.append(contentsOf: convertStatement(statement))
			}
			else if let expression = item.as(ExprSyntax.self) {
				if shouldConvertToStatement(expression) {
					try result.append(convertExpressionToStatement(expression))
				}
				else {
					try result.append(ExpressionStatement(
						range: expression.getRange(inFile: self.sourceFile),
						expression: convertExpression(expression)))
				}
			}
			else {
				try result.append(errorStatement(
					forASTNode: Syntax(statement),
					withMessage: "Unknown top-level statement"))
			}
		}

		return result
	}

	/// Separates declarations from statements for use in a main file. Returns a tuple in the format
	/// `(declarations, statements)`.
	func filterStatements(
		_ allStatements: MutableList<Statement>)
		-> (MutableList<Statement>, MutableList<Statement>)
	{
		let declarations: MutableList<Statement> = []
		let statements: MutableList<Statement> = []

		var isInTopOfFileComments = true
		var lastTopOfFileCommentLine = 0

		for statement in allStatements {

			// Special case: comments at the top of the source file (i.e. license comments, etc)
			// will be put outside of the main function so they're at the top of the source file
			if isInTopOfFileComments {
				if let commentStatement = statement as? CommentStatement {
					if let range = commentStatement.range,
						lastTopOfFileCommentLine == range.lineStart - 1
					{
						lastTopOfFileCommentLine = range.lineEnd
						declarations.append(statement)
						continue
					}
				}

				isInTopOfFileComments = false
			}

			// Special case: other comments in main files will be ignored because we can't know if
			// they're supposed to be in the main function or not
			if statement is CommentStatement {
				continue
			}

			// Special case: expression statements may be literal declarations or normal statements
			if let expressionStatement = statement as? ExpressionStatement {
				if let literalCodeExpression =
						expressionStatement.expression as? LiteralCodeExpression,
					!literalCodeExpression.shouldGoToMainFunction
				{
					declarations.append(statement)
				}
				else {
					statements.append(statement)
				}

				continue
			}

			// Common cases: declarations go outside the main function, everything else goes inside.
			if statement is ProtocolDeclaration ||
				statement is ClassDeclaration ||
				statement is StructDeclaration ||
				statement is ExtensionDeclaration ||
				statement is FunctionDeclaration ||
				statement is EnumDeclaration ||
				statement is TypealiasDeclaration
			{
				declarations.append(statement)
			}
			else {
				statements.append(statement)
			}
		}

		return (declarations, statements)
	}

	struct LeadingCommentInformation {
		let commentStatements: MutableList<Statement>
		let shouldIgnoreNextStatement: Bool
	}

	func convertLeadingComments(fromSyntax syntax: Syntax) -> LeadingCommentInformation {
		let result: MutableList<Statement> = []
		var shouldIgnoreNextStatement = false

		if let leadingTrivia = syntax.leadingTrivia {
			var startOffset = syntax.position.utf8Offset
			for trivia in leadingTrivia {
				let endOffset = startOffset + trivia.sourceLength.utf8Length
				if case let .lineComment(comment) = trivia {
					let commentRange = SourceFileRange.getRange(
						withStartOffset: startOffset,
						withEndOffset: endOffset - 1, // Inclusive end
						inFile: self.sourceFile)

					// TODO: Remove the `//` added by the KotlinTranslator so we don't have to do
					// it here
					let commentContents = String(comment.dropFirst(2))
					let cleanComment = String(commentContents.drop(while: {
						$0 == " " || $0 == "\t"
					}))

					if let insertComment =
						SourceFile.getTranslationCommentFromString(cleanComment)
					{
						if let commentValue = insertComment.value {
							if insertComment.key == .insertInMain {
								result.append(ExpressionStatement(
									range: commentRange,
									expression: LiteralCodeExpression(
										range: commentRange,
										string: commentValue,
										shouldGoToMainFunction: true)))
							}
							else if insertComment.key == .insert {
								result.append(ExpressionStatement(
									range: commentRange,
									expression: LiteralCodeExpression(
										range: commentRange,
										string: commentValue,
										shouldGoToMainFunction: false)))
							}
							else if insertComment.key == .output {
								if let fileExtension = Utilities.getExtension(of: commentValue),
									(fileExtension == .swiftAST ||
									 fileExtension == .gryphonASTRaw ||
									 fileExtension == .gryphonAST ||
									 fileExtension == .kt)
								{
									outputFileMap[fileExtension] = insertComment.value
								}
								else {
									Compiler.handleWarning(
										message: "Unsupported output file extension in " +
											"\"\(commentValue)\". Did you mean to use \".kt\"?",
										sourceFile: sourceFile,
										sourceFileRange: commentRange)
								}
							}
						}
						else if insertComment.key == .ignore {
							shouldIgnoreNextStatement = true
						}
					}
					else {
						result.append(CommentStatement(
							range: commentRange,
							value: commentContents))
					}
				}
			
				startOffset = endOffset
			}
		}

		return LeadingCommentInformation(
			commentStatements: result,
			shouldIgnoreNextStatement: shouldIgnoreNextStatement)
	}

	// MARK: - Statements
	func convertStatement(_ statement: StmtSyntax) throws -> MutableList<Statement> {
		let leadingCommentInformation = convertLeadingComments(fromSyntax: Syntax(statement))
		let result: MutableList<Statement> = leadingCommentInformation.commentStatements

		if leadingCommentInformation.shouldIgnoreNextStatement {
			return result
		}

		if let returnStatement = statement.as(ReturnStmtSyntax.self) {
			try result.append(convertReturnStatement(returnStatement))
			return result
		}

		return try [errorStatement(
			forASTNode: Syntax(statement),
			withMessage: "Unknown declaration"), ]
	}

	func convertReturnStatement(
		_ returnStatement: ReturnStmtSyntax)
		throws -> Statement
	{
		let expression: Expression?
		if let expressionSyntax = returnStatement.expression {
			expression = try convertExpression(expressionSyntax)
		}
		else {
			expression = nil
		}

		return ReturnStatement(
			range: returnStatement.getRange(inFile: self.sourceFile),
			expression: expression,
			label: nil)
	}

	// MARK: - Declarations

	func convertDeclaration(_ declaration: DeclSyntax) throws -> MutableList<Statement> {
		let leadingCommentInformation = convertLeadingComments(fromSyntax: Syntax(declaration))
		let result: MutableList<Statement> = leadingCommentInformation.commentStatements

		if leadingCommentInformation.shouldIgnoreNextStatement {
			return result
		}

		if let variableDeclaration = declaration.as(VariableDeclSyntax.self) {
			try result.append(contentsOf: convertVariableDeclaration(variableDeclaration)
				.forceCast(to: MutableList<Statement>.self))
			return result
		}
		if let functionDeclaration = declaration.as(FunctionDeclSyntax.self) {
			try result.append(convertFunctionDeclaration(functionDeclaration))
			return result
		}
		if let importDeclaration = declaration.as(ImportDeclSyntax.self) {
			try result.append(convertImportDeclaration(importDeclaration))
			return result
		}

		return try [errorStatement(
			forASTNode: Syntax(declaration),
			withMessage: "Unknown declaration"), ]
	}

	func convertImportDeclaration(
		_ importDeclaration: ImportDeclSyntax)
		throws -> Statement
	{
		let moduleName = try importDeclaration.path.getLiteralText(fromSourceFile: self.sourceFile)
		return ImportDeclaration(
			range: importDeclaration.getRange(inFile: self.sourceFile),
			moduleName: moduleName)
	}

	func convertFunctionDeclaration(
		_ functionDeclaration: FunctionDeclSyntax)
		throws -> Statement
	{
		let prefix = functionDeclaration.identifier.text

		let parameters: MutableList<FunctionParameter> = []
		// Parameter tokens: `firstName` `secondName (optional)` `:` `type`
		for parameter in functionDeclaration.signature.input.parameterList {
			if let firstName = parameter.firstName?.text,
				let typeToken = parameter.children.last,
				let typeSyntax = typeToken.as(TypeSyntax.self)
			{
				// Get the parameter names
				let label: String
				let apiLabel: String?
				if let secondName = parameter.secondName?.text {
					if firstName == "_" {
						apiLabel = nil
					}
					else {
						apiLabel = firstName
					}
					label = secondName
				}
				else {
					// If there's just one name, it'll the same for implementation and API
					label = firstName
					apiLabel = firstName
				}

				let typeName = try convertType(typeSyntax)

				parameters.append(FunctionParameter(
					label: label,
					apiLabel: apiLabel,
					typeName: typeName,
					value: nil))
			}
			else {
				try parameters.append(FunctionParameter(
					label: "<<Error>>",
					apiLabel: nil,
					typeName: "<<Error>>",
					value: errorExpression(
						forASTNode: Syntax(parameter),
						withMessage: "Expected parameter to always have a first name and a type.")))
			}
		}

		let inputType = "(" + parameters.map { $0.typeName }.joined(separator: ", ") + ")"

		let returnType: String
		if let returnTypeSyntax = functionDeclaration.signature.output?.returnType {
			returnType = try convertType(returnTypeSyntax)
		}
		else {
			returnType = "Void"
		}

		let functionType = inputType + " -> " + returnType

		let statements: MutableList<Statement>
		if let statementsSyntax = functionDeclaration.body?.statements {
			statements = try convertStatements(statementsSyntax)
		}
		else {
			statements = []
		}

		return FunctionDeclaration(
			range: functionDeclaration.getRange(inFile: sourceFile),
			prefix: prefix,
			parameters: parameters,
			returnType: returnType,
			functionType: functionType,
			genericTypes: [],
			isOpen: false,
			isImplicit: false,
			isStatic: false,
			isMutating: false,
			isPure: false,
			isJustProtocolInterface: false,
			extendsType: nil,
			statements: statements,
			access: nil,
			annotations: [])
	}

	func convertVariableDeclaration(
		_ variableDeclaration: VariableDeclSyntax)
		throws -> MutableList<Statement>
	{
		let isLet = (variableDeclaration.letOrVarKeyword.text == "let")
		let annotations: MutableList<String> = MutableList(variableDeclaration.modifiers?.compactMap {
			return $0.getText()
		} ?? [])

		let result: MutableList<VariableDeclaration> = []
		let errors: MutableList<Statement> = []

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
					range: variableDeclaration.getRange(inFile: self.sourceFile),
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
				try errors.append(
					errorStatement(
						forASTNode: Syntax(patternBinding),
						withMessage: "Failed to convert variable declaration: unknown pattern " +
						"binding"))
			}
		}

		// Propagate the type annotations: `let x, y: Double` becomes `val x; val y: Double`, but it
		// needs to be `val x: Double; val y: Double`.
		if result.count > 1, let lastTypeAnnotation = result.last?.typeAnnotation {
			for declaration in result {
				declaration.typeAnnotation = declaration.typeAnnotation ?? lastTypeAnnotation
			}
		}

		let resultStatements = result.forceCast(to: MutableList<Statement>.self)
		resultStatements.append(contentsOf: errors)
		return resultStatements
	}

	// MARK: - Statement expressions

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

		// Should never be reached because we only call this method with known statements checked
		// with `shouldConvertToStatement`.
		return try errorStatement(forASTNode: Syntax(expression), withMessage: "Unknown statement")
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
				range: sequenceExpression.getRange(inFile: self.sourceFile),
				leftHand: translatedLeftExpression,
				rightHand: translatedRightExpression)
		}



		return try errorStatement(
			forASTNode: Syntax(sequenceExpression),
			withMessage: "Failed to convert sequence expression")
	}

	// MARK: - Expressions

	func convertExpression(_ expression: ExprSyntax) throws -> Expression {
		if let stringLiteralExpression = expression.as(StringLiteralExprSyntax.self) {
			return try convertStringLiteralExpression(stringLiteralExpression)
		}
		if let integerLiteralExpression = expression.as(IntegerLiteralExprSyntax.self) {
			return try convertIntegerLiteralExpression(integerLiteralExpression)
		}
		if let booleanLiteralExpression = expression.as(BooleanLiteralExprSyntax.self) {
			return try convertBooleanLiteralExpression(booleanLiteralExpression)
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

		return try errorExpression(
			forASTNode: Syntax(expression),
			withMessage: "Unknown expression")
	}

	func convertNilLiteralExpression(
		_ nilLiteralExpression: NilLiteralExprSyntax)
		throws -> Expression
	{
		return NilLiteralExpression(range: nilLiteralExpression.getRange(inFile: self.sourceFile))
	}

	func convertBooleanLiteralExpression(
		_ booleanLiteralExpression: BooleanLiteralExprSyntax)
		throws -> Expression
	{
		return LiteralBoolExpression(
			range: booleanLiteralExpression.getRange(inFile: self.sourceFile),
			value: (booleanLiteralExpression.booleanLiteral.text == "true"))
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
				range: functionCallExpression.getRange(inFile: self.sourceFile),
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
			range: tupleExprElementListSyntax.getRange(inFile: self.sourceFile),
			pairs: pairs)
	}

	func convertIdentifierExpression(
		_ identifierExpression: IdentifierExprSyntax)
		throws -> Expression
	{
		// TODO: DeclRef should have optional type
		return DeclarationReferenceExpression(
			range: identifierExpression.getRange(inFile: self.sourceFile),
			identifier: identifierExpression.identifier.text,
			typeName: identifierExpression.getType(fromList: self.expressionTypes) ?? "",
			isStandardLibrary: false,
			isImplicit: false)
	}

	func convertIntegerLiteralExpression(
		_ integerLiteralExpression: IntegerLiteralExprSyntax)
		throws -> Expression
	{
		if let typeName = integerLiteralExpression.getType(fromList: self.expressionTypes) {
			if typeName == "Double",
				let doubleValue = Double(integerLiteralExpression.digits.text)
			{
				return LiteralDoubleExpression(
					range: integerLiteralExpression.getRange(inFile: self.sourceFile),
					value: doubleValue)
			}
		}

		if let intValue = Int64(integerLiteralExpression.digits.text) {
			return LiteralIntExpression(
				range: integerLiteralExpression.getRange(inFile: self.sourceFile),
				value: intValue)
		}

		return try errorExpression(
			forASTNode: Syntax(integerLiteralExpression),
			withMessage: "Failed to convert integer literal expression")
	}

	func convertStringLiteralExpression(
		_ stringLiteralExpression: StringLiteralExprSyntax)
		throws -> Expression
	{
		let range = stringLiteralExpression.getRange(inFile: self.sourceFile)

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
					range: stringSegment.getRange(inFile: self.sourceFile),
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

			return try errorExpression(
				forASTNode: Syntax(stringLiteralExpression),
				withMessage: "Unrecognized expression in string literal interpolation")
		}

		return InterpolatedStringLiteralExpression(
			range: range,
			expressions: expressions)
	}

	// MARK: - Helper methods

	func convertType(_ typeSyntax: TypeSyntax) throws -> String {
		if let optionalType = typeSyntax.as(OptionalTypeSyntax.self) {
			return try convertType(optionalType.wrappedType) + "?"
		}
		if let arrayType = typeSyntax.as(ArrayTypeSyntax.self) {
			return try "[" + convertType(arrayType.elementType) + "]"
		}

		if let text = typeSyntax.getText() {
			return text
		}

		try Compiler.handleError(
			message: "Unknown type",
			ast: typeSyntax.toPrintableTree(),
			sourceFile: sourceFile,
			sourceFileRange: typeSyntax.getRange(inFile: sourceFile))
		return "<<Error>>"
	}

	func errorStatement(
		forASTNode ast: Syntax,
		withMessage errorMessage: String)
		throws -> ErrorStatement
	{
		let message = "Failed to turn SwiftSyntax node into Gryphon AST: " + errorMessage + "."
		let range = ast.getRange(inFile: sourceFile)

		try Compiler.handleError(
			message: message,
			ast: ast.toPrintableTree(),
			sourceFile: sourceFile,
			sourceFileRange: range)
		return ErrorStatement(range: range)
	}

	func errorExpression(
		forASTNode ast: Syntax,
		withMessage errorMessage: String)
		throws -> ErrorExpression
	{
		let message = "Failed to turn SwiftSyntax node into Gryphon AST: " + errorMessage + "."
		let range = ast.getRange(inFile: sourceFile)

		try Compiler.handleError(
			message: message,
			ast: ast.toPrintableTree(),
			sourceFile: sourceFile,
			sourceFileRange: range)
		return ErrorExpression(range: range)
	}
}

// MARK: - Helper extensions

extension SyntaxProtocol {
	func getText() -> String? {
		if let firstChild = self.children.first,
			let childTokenSyntax = firstChild.as(TokenSyntax.self)
		{
			return childTokenSyntax.text
		}

		return nil
	}

	/// Returns the text as it is in the source file, including any trivia in the middle of the
	/// tokens.
	func getLiteralText(fromSourceFile sourceFile: SourceFile) throws -> String {
		let startOffset = self.positionAfterSkippingLeadingTrivia.utf8Offset
		let length = self.contentLength.utf8Length
		let endOffset = startOffset + length

		let contents = sourceFile.contents
		let startIndex = contents.utf8.index(contents.utf8.startIndex, offsetBy: startOffset)
		let endIndex = contents.utf8.index(contents.utf8.startIndex, offsetBy: endOffset)

		guard let result = String(sourceFile.contents.utf8[startIndex..<endIndex]) else {
			try Compiler.handleError(
				message: "Failed to get the literal text starting at offset \(startOffset) with " +
					"length \(length)",
				ast: self.toPrintableTree(),
				sourceFile: sourceFile,
				sourceFileRange: getRange(inFile: sourceFile))
			return "<<Error>>"
		}

		return result
	}
}

private extension SyntaxProtocol {
	func getRange(inFile filePath: SourceFile) -> SourceFileRange? {
		let startOffset = self.positionAfterSkippingLeadingTrivia.utf8Offset
		let length = self.contentLength.utf8Length

		// The end in a source file range is inclusive (-1)
		let endOffset = startOffset + length - 1
		return SourceFileRange.getRange(
			withStartOffset: startOffset,
			withEndOffset: endOffset,
			inFile: filePath)
	}

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

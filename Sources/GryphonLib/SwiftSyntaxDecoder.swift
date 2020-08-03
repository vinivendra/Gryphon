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
	/// The transpilation context, used for information such as if we should default to open
	let context: TranspilationContext

	init(filePath: String, context: TranspilationContext) throws {
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
		self.context = context
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

	func convertStatements<Body>(
		_ statements: Body)
		throws -> MutableList<Statement>
		where Body: SyntaxList
	{
		let result: MutableList<Statement> = []

		for statement in statements {
			let item: Syntax = statement.element

			let leadingCommentInformation = convertLeadingComments(forStatement: item)
			if leadingCommentInformation.shouldIgnoreNextStatement {
				continue
			}
			else {
				result.append(contentsOf: leadingCommentInformation.commentStatements)
			}

			if let declaration = item.as(DeclSyntax.self) {
				try result.append(contentsOf: convertDeclaration(declaration))
			}
			else if let statement = item.as(StmtSyntax.self) {
				try result.append(convertStatement(statement))
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

	func convertLeadingComments(forStatement syntax: Syntax) -> LeadingCommentInformation {
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
					let cleanComment = commentContents.trimmingWhitespaces()

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
										shouldGoToMainFunction: true,
										typeName: nil)))
							}
							else if insertComment.key == .insert {
								result.append(ExpressionStatement(
									range: commentRange,
									expression: LiteralCodeExpression(
										range: commentRange,
										string: commentValue,
										shouldGoToMainFunction: false,
										typeName: nil)))
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
							// TODO: add a warning for translation comments at the end of lines
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

	func convertLeadingComments(forExpression syntax: Syntax) -> LiteralCodeExpression? {
		if let leadingTrivia = syntax.leadingTrivia {
			var startOffset = syntax.position.utf8Offset
			for trivia in leadingTrivia {
				let endOffset = startOffset + trivia.sourceLength.utf8Length

				let maybeCommentString: String?
				switch trivia {
				case let .lineComment(comment):
					maybeCommentString = String(comment.dropFirst(2))
				case let .blockComment(comment):
					maybeCommentString = String(comment.dropFirst(2).dropLast(2))
				default:
					maybeCommentString = nil
				}

				if let commentContents = maybeCommentString {
					let commentRange = SourceFileRange.getRange(
						withStartOffset: startOffset,
						withEndOffset: endOffset - 1, // Inclusive end
						inFile: self.sourceFile)

					let cleanComment = commentContents.trimmingWhitespaces()

					if let insertComment =
						SourceFile.getTranslationCommentFromString(cleanComment)
					{
						if let commentValue = insertComment.value {
							if insertComment.key == .value {
								return LiteralCodeExpression(
									range: commentRange,
									string: commentValue,
									shouldGoToMainFunction: false,
									typeName: nil)
							}
						}
					}
				}

				startOffset = endOffset
			}
		}

		return nil
	}

	// MARK: - Statements
	func convertStatement(_ statement: StmtSyntax) throws -> Statement {
		if let returnStatement = statement.as(ReturnStmtSyntax.self) {
			return try convertReturnStatement(returnStatement)
		}
		if let ifStatement = statement.as(IfStmtSyntax.self) {
			return try convertIfStatement(ifStatement)
		}
		if let forStatement = statement.as(ForInStmtSyntax.self) {
			return try convertForStatement(forStatement)
		}

		return try errorStatement(
			forASTNode: Syntax(statement),
			withMessage: "Unknown statement")
	}

	func convertForStatement(
		_ forStatement: ForInStmtSyntax)
		throws -> Statement
	{
		let variable = try convertPatternExpression(forStatement.pattern)
		let collection = try convertExpression(forStatement.sequenceExpr)
		let statements = try convertStatements(forStatement.body.statements)

		return ForEachStatement(
			range: forStatement.getRange(inFile: self.sourceFile),
			collection: collection,
			variable: variable,
			statements: statements)
	}

	func convertIfStatement(
		_ ifStatement: IfStmtSyntax)
		throws -> IfStatement
	{
		let conditions: MutableList<IfStatement.IfCondition> = []
		for condition in ifStatement.conditions {
			if let child = condition.children.first {
				if let expressionSyntax = child.as(ExprSyntax.self) {
					let expression = try convertExpression(expressionSyntax)
					conditions.append(.condition(expression: expression))
				}
				else if let optionalBinding = child.as(OptionalBindingConditionSyntax.self),
					let identifier = optionalBinding.pattern.getText()
				{
					let expression = try convertExpression(optionalBinding.initializer.value)
					conditions.append(IfStatement.IfCondition.declaration(variableDeclaration:
						VariableDeclaration(
							range: optionalBinding.getRange(inFile: self.sourceFile),
							identifier: identifier,
							typeAnnotation: expression.swiftType,
							expression: expression,
							getter: nil,
							setter: nil,
							access: nil,
							isOpen: false,
							isLet: optionalBinding.letOrVarKeyword.text == "let",
							isImplicit: false,
							isStatic: false,
							extendsType: nil,
							annotations: [])))
				}
			}
			else {
				let expression = try errorExpression(
					forASTNode: Syntax(condition),
					withMessage: "Unable to convert if condition")
				conditions.append(.condition(expression: expression))
			}
		}

		let statements = try convertStatements(ifStatement.body.statements)

		let elseStatement: IfStatement?
		if let elseIfSyntax = ifStatement.children.last?.as(IfStmtSyntax.self) {
			elseStatement = try convertIfStatement(elseIfSyntax)
		}
		else if let elseBody = ifStatement.elseBody?.as(CodeBlockSyntax.self) {
			let elseBodyStatements = try convertStatements(elseBody.statements)
			elseStatement = IfStatement(
				range: elseBody.getRange(inFile: self.sourceFile),
				conditions: [],
				declarations: [],
				statements: elseBodyStatements,
				elseStatement: nil,
				isGuard: false)
		}
		else {
			elseStatement = nil
		}

		return IfStatement(
			range: ifStatement.getRange(inFile: self.sourceFile),
			conditions: conditions,
			declarations: [],
			statements: statements,
			elseStatement: elseStatement,
			isGuard: false)
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

	func convertDeclaration(_ declaration: DeclSyntax) throws -> List<Statement> {
		if let classDeclaration = declaration.as(ClassDeclSyntax.self) {
			return try [convertClassDeclaration(classDeclaration)]
		}
		if let variableDeclaration = declaration.as(VariableDeclSyntax.self) {
			return try convertVariableDeclaration(variableDeclaration)
		}
		if let functionDeclaration = declaration.as(FunctionDeclSyntax.self) {
			return try [convertFunctionDeclaration(functionDeclaration)]
		}
		if let importDeclaration = declaration.as(ImportDeclSyntax.self) {
			return try [convertImportDeclaration(importDeclaration)]
		}

		return try [errorStatement(
			forASTNode: Syntax(declaration),
			withMessage: "Unknown declaration"), ]
	}

	func convertClassDeclaration(
		_ classDeclaration: ClassDeclSyntax)
		throws -> Statement
	{
		let inheritances = try classDeclaration.inheritanceClause?.inheritedTypeCollection.map {
				try convertType($0.typeName)
		} ?? []

		let accessAndAnnotations =
			getAccessAndAnnotations(fromModifiers: classDeclaration.modifiers)

		return ClassDeclaration(
			range: classDeclaration.getRange(inFile: self.sourceFile),
			className: classDeclaration.identifier.text,
			annotations: [],
			access: accessAndAnnotations.access,
			isOpen: true,
			inherits: MutableList(inheritances),
			members: try convertStatements(classDeclaration.members.members))
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
		// Parameter tokens: `firstName` `secondName (optional)` `:` `type` `, (optional)`
		for parameter in functionDeclaration.signature.input.parameterList {
			if let firstName = parameter.firstName?.text,
				let typeToken = parameter.children.first(where: { $0.is(TypeSyntax.self) })
			{
				let typeSyntax = typeToken.as(TypeSyntax.self)!

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
						withMessage: "Expected parameter to always have a first name and a type")))
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

		let isOpen: Bool
		if let modifiers = functionDeclaration.modifiers,
			modifiers.contains(where: { $0.name.text == "final" })
		{
			isOpen = false
		}
		else if let modifiers = functionDeclaration.modifiers,
			modifiers.contains(where: { $0.name.text == "open" })
		{
			isOpen = true
		}
		else {
			isOpen = !self.context.defaultsToFinal
		}

		let accessAndAnnotations =
			getAccessAndAnnotations(fromModifiers: functionDeclaration.modifiers)

		return FunctionDeclaration(
			range: functionDeclaration.getRange(inFile: sourceFile),
			prefix: prefix,
			parameters: parameters,
			returnType: returnType,
			functionType: functionType,
			genericTypes: [],
			isOpen: isOpen,
			isImplicit: false,
			isStatic: false,
			isMutating: false,
			isPure: false,
			isJustProtocolInterface: false,
			extendsType: nil,
			statements: statements,
			access: accessAndAnnotations.access,
			annotations: accessAndAnnotations.annotations)
	}

	func convertVariableDeclaration(
		_ variableDeclaration: VariableDeclSyntax)
		throws -> MutableList<Statement>
	{
		let isLet = (variableDeclaration.letOrVarKeyword.text == "let")

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

				let isOpen: Bool
				if let modifiers = variableDeclaration.modifiers,
					modifiers.contains(where: { $0.name.text == "final" })
				{
					isOpen = false
				}
				else if let modifiers = variableDeclaration.modifiers,
					modifiers.contains(where: { $0.name.text == "open" })
				{
					isOpen = true
				}
				else if isLet {
					// Only var's can be open in Swift
					isOpen = false
				}
				else {
					isOpen = !self.context.defaultsToFinal
				}

				let accessAndAnnotations =
					getAccessAndAnnotations(fromModifiers: variableDeclaration.modifiers)

				result.append(VariableDeclaration(
					range: variableDeclaration.getRange(inFile: self.sourceFile),
					identifier: identifier,
					typeAnnotation: annotatedType,
					expression: expression,
					getter: nil,
					setter: nil,
					access: accessAndAnnotations.access,
					isOpen: isOpen,
					isLet: isLet,
					isImplicit: false,
					isStatic: false,
					extendsType: nil,
					annotations: accessAndAnnotations.annotations))
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

	private func getAccessAndAnnotations(
		fromModifiers modifiers: ModifierListSyntax?)
		-> (access: String?, annotations: MutableList<String>)
	{
		if let modifiers = modifiers {
			var array = Array(modifiers)
			let index = array.partition { (syntax: DeclModifierSyntax) -> Bool in
					return syntax.name.text == "open" ||
						syntax.name.text == "public" ||
						syntax.name.text == "internal" ||
						syntax.name.text == "fileprivate" ||
						syntax.name.text == "private"
				}
			let annonationSyntaxes = array[..<index]
			let accessSyntaxes = array[index...]
			let access = accessSyntaxes.first?.name.text
			let annotations = MutableList(annonationSyntaxes.map { $0.name.text })
			return (access, annotations)
		}
		else {
			return (nil, [])
		}
	}

	// MARK: - Statement expressions

	func convertExpressionToStatement(_ expression: ExprSyntax) throws -> Statement {
		if let sequenceExpression = expression.as(SequenceExprSyntax.self) {
			return try convertSequenceExpressionAsAssignment(sequenceExpression)
		}

		// Should never be reached because we only call this method with known statements checked
		// with `shouldConvertToStatement`.
		return try errorStatement(forASTNode: Syntax(expression), withMessage: "Unknown statement")
	}

	func shouldConvertToStatement(_ expression: ExprSyntax) -> Bool {
		if let sequenceExpression = expression.as(SequenceExprSyntax.self) {
			return isAssignmentExpression(sequenceExpression)
		}

		return false
	}

	func isAssignmentExpression(
		_ sequenceExpression: SequenceExprSyntax)
		-> Bool
	{
		let expressionList = List(sequenceExpression.elements)

		if expressionList.count >= 3,
			expressionList[1].is(AssignmentExprSyntax.self)
		{
			return true
		}
		else {
			return false
		}
	}

	/// Assignment expressions are just sequence expressions that start with `expression` `=` and
	/// then continue as normal sequence expressions (e.g. `expression` `=` `1` + `2`).
	/// This method is used because assignments have to be translated as statements. It translates
	/// the expression (and the `=` token) then leaves the rest of the expressions to the
	/// `convertSequenceExpression` method, using `ignoringFirstElements: 2` to signal that the
	/// `expression` and the `=` were already translated.
	func convertSequenceExpressionAsAssignment(
		_ sequenceExpression: SequenceExprSyntax)
		throws -> Statement
	{
		let range = sequenceExpression.getRange(inFile: self.sourceFile)
		let expressionList = List(sequenceExpression.elements)

		let leftExpression = expressionList[0]

		let convertedRightExpression = try convertSequenceExpression(
			sequenceExpression,
			limitedToElements: List(sequenceExpression.elements.dropFirst(2)))

		// If it's a discarded statement (e.g. `_ = 0`) make t just the right-side expression
		if leftExpression.is(DiscardAssignmentExprSyntax.self) {
			return ExpressionStatement(range: range, expression: convertedRightExpression)
		}
		else {
			let convertedLeftExpression = try convertExpression(leftExpression)
			return AssignmentStatement(
				range: range,
				leftHand: convertedLeftExpression,
				rightHand: convertedRightExpression)
		}
	}

	// MARK: - Expressions

	func convertExpression(_ expression: ExprSyntax) throws -> Expression {
		if let commentExpression = convertLeadingComments(forExpression: Syntax(expression)) {
			// Set the LiteralCodeExpression's type to the type of the expression it's replacing
			commentExpression.typeName = expression.getType(fromList: self.expressionTypes)
			return commentExpression
		}

		if let stringLiteralExpression = expression.as(StringLiteralExprSyntax.self) {
			return try convertStringLiteralExpression(stringLiteralExpression)
		}
		if let integerLiteralExpression = expression.as(IntegerLiteralExprSyntax.self) {
			return try convertIntegerLiteralExpression(integerLiteralExpression)
		}
		if let floatLiteralExpression = expression.as(FloatLiteralExprSyntax.self) {
			return try convertFloatLiteralExpression(floatLiteralExpression)
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
		if let arrayExpression = expression.as(ArrayExprSyntax.self) {
			return try convertArrayLiteralExpression(arrayExpression)
		}
		if let dictionaryExpression = expression.as(DictionaryExprSyntax.self) {
			return try convertDictionaryLiteralExpression(dictionaryExpression)
		}
		if let memberAccessExpression = expression.as(MemberAccessExprSyntax.self) {
			return try convertMemberAccessExpression(memberAccessExpression)
		}
		if let sequenceExpression = expression.as(SequenceExprSyntax.self) {
			return try convertSequenceExpression(sequenceExpression)
		}
		if let closureExpression = expression.as(ClosureExprSyntax.self) {
			return try convertClosureExpression(closureExpression)
		}
		if let forcedValueExpression = expression.as(ForcedValueExprSyntax.self) {
			return try convertForcedValueExpression(forcedValueExpression)
		}
		if let subscriptExpression = expression.as(SubscriptExprSyntax.self) {
			return try convertSubscriptExpression(subscriptExpression)
		}
		if let postfixUnaryExpression = expression.as(PostfixUnaryExprSyntax.self) {
			return try convertPostfixUnaryExpression(postfixUnaryExpression)
		}
		if let prefixUnaryExpression = expression.as(PrefixOperatorExprSyntax.self) {
			return try convertPrefixOperatorExpression(prefixUnaryExpression)
		}
		if let specializeExpression = expression.as(SpecializeExprSyntax.self) {
			return try convertSpecializeExpression(specializeExpression)
		}
		if let tupleExpression = expression.as(TupleExprSyntax.self) {
			return try convertTupleExpression(tupleExpression)
		}
		if let ternaryExpression = expression.as(TernaryExprSyntax.self) {
			return try convertTernaryExpression(ternaryExpression)
		}
		if let nilLiteralExpression = expression.as(NilLiteralExprSyntax.self) {
			return try convertNilLiteralExpression(nilLiteralExpression)
		}

		// Expressions that can be translated as their last subexpression
		if expression.is(InOutExprSyntax.self),
			let lastChild = expression.children.last,
			let subExpression = lastChild.as(ExprSyntax.self)
		{
			return try convertExpression(subExpression)
		}

		return try errorExpression(
			forASTNode: Syntax(expression),
			withMessage: "Unknown expression")
	}

	/// Returns:
	/// - a `DeclarationReferenceExpression` if it's an identifier pattern;
	/// - a `TupleExpression` if it's a tuple pattern;
	/// - `nil` if it's a wildcard pattern;
	func convertPatternExpression(
		_ patternExpression: PatternSyntax)
		throws -> Expression?
	{
		if let identifierPattern = patternExpression.as(IdentifierPatternSyntax.self) {
			return DeclarationReferenceExpression(
				range: identifierPattern.getRange(inFile: self.sourceFile),
				identifier: identifierPattern.identifier.text,
				typeName: identifierPattern.getType(fromList: self.expressionTypes),
				isStandardLibrary: false,
				isImplicit: false)
		}
		else if let tuplePattern = patternExpression.as(TuplePatternSyntax.self) {
			let expressions = try List(tuplePattern.elements).map
				{ (patternSyntax: TuplePatternElementSyntax) -> Expression in
					try convertPatternExpression(patternSyntax.pattern) ??
						errorExpression(
							forASTNode: Syntax(patternSyntax),
							withMessage: "Unsupported pattern inside tuple pattern")
				}
			let labeledExpressions = expressions.map {
					LabeledExpression(label: nil, expression: $0)
				}
			return TupleExpression(
				range: tuplePattern.getRange(inFile: self.sourceFile),
				pairs: labeledExpressions.toMutableList())
		}
		else if patternExpression.is(WildcardPatternSyntax.self) {
			return nil
		}
		else {
			return try errorExpression(
				forASTNode: Syntax(patternExpression),
				withMessage: "Unable to convert pattern")
		}
	}

	func convertTernaryExpression(
		_ ternaryExpression: TernaryExprSyntax)
		throws -> Expression
	{
		let condition = try convertExpression(ternaryExpression.conditionExpression)
		let trueExpression = try convertExpression(ternaryExpression.firstChoice)
		let falseExpression = try convertExpression(ternaryExpression.secondChoice)

		return IfExpression(
			range: ternaryExpression.getRange(inFile: self.sourceFile),
			condition: condition,
			trueExpression: trueExpression,
			falseExpression: falseExpression)
	}

	func convertTupleExpression(
		_ tupleExpression: TupleExprSyntax)
		throws -> Expression
	{
		return try convertTupleExpressionElementList(
			tupleExpression.elementList,
			withType: tupleExpression.getType(fromList: self.expressionTypes))
	}

	/// A generic expression whose generic arguments are being specialized
	func convertSpecializeExpression(
		_ specializeExpression: SpecializeExprSyntax)
		throws -> Expression
	{
		guard let identifierExpression =
			specializeExpression.expression.as(IdentifierExprSyntax.self) else
		{
			return try errorExpression(
				forASTNode: Syntax(specializeExpression),
				withMessage: "Failed to convert specialize expression")
		}

		let identifier = identifierExpression.identifier.text
		let genericTypes = try specializeExpression.genericArgumentClause.arguments.map {
				try convertType($0.argumentType)
			}.joined(separator: ", ")

		return TypeExpression(
			range: specializeExpression.getRange(inFile: self.sourceFile),
			typeName: "\(identifier)<\(genericTypes)>")
	}

	func convertPrefixOperatorExpression(
		_ prefixOperatorExpression: PrefixOperatorExprSyntax)
		throws -> Expression
	{
		guard let typeName = prefixOperatorExpression.getType(fromList: self.expressionTypes),
			let operatorSymbol = prefixOperatorExpression.operatorToken?.text else
		{
			return try errorExpression(
				forASTNode: Syntax(prefixOperatorExpression),
				withMessage: "Unable to convert prefix operator expression")
		}

		let subExpression = try convertExpression(prefixOperatorExpression.postfixExpression)

		return PrefixUnaryExpression(
			range: prefixOperatorExpression.getRange(inFile: self.sourceFile),
			subExpression: subExpression,
			operatorSymbol: operatorSymbol,
			typeName: typeName)
	}

	func convertPostfixUnaryExpression(
		_ postfixUnaryExpression: PostfixUnaryExprSyntax)
		throws -> Expression
	{
		guard let typeName = postfixUnaryExpression.getType(fromList: self.expressionTypes) else {
			return try errorExpression(
				forASTNode: Syntax(postfixUnaryExpression),
				withMessage: "Unable to get type for postfix unary expression")
		}

		let subExpression = try convertExpression(postfixUnaryExpression.expression)
		let operatorSymbol = postfixUnaryExpression.operatorToken.text

		return PostfixUnaryExpression(
			range: postfixUnaryExpression.getRange(inFile: self.sourceFile),
			subExpression: subExpression,
			operatorSymbol: operatorSymbol,
			typeName: typeName)
	}

	func convertSubscriptExpression(
		_ subscriptExpression: SubscriptExprSyntax)
		throws -> Expression
	{
		guard let indexExpression = subscriptExpression.argumentList.first?.expression,
			let typeName = subscriptExpression.getType(fromList: self.expressionTypes) else
		{
			return try errorExpression(
				forASTNode: Syntax(subscriptExpression),
				withMessage: "Unable to convert index expression")
		}

		let convertedIndexExpression = try convertExpression(indexExpression)
		let convertedCalledExpression = try convertExpression(subscriptExpression.calledExpression)

		return SubscriptExpression(
			range: subscriptExpression.getRange(inFile: self.sourceFile),
			subscriptedExpression: convertedCalledExpression,
			indexExpression: convertedIndexExpression,
			typeName: typeName)
	}

	func convertForcedValueExpression(
		_ forcedValueExpression: ForcedValueExprSyntax)
		throws -> Expression
	{
		return try ForceValueExpression(
			range: forcedValueExpression.getRange(inFile: self.sourceFile),
			expression: convertExpression(forcedValueExpression.expression))
	}

	func convertClosureExpression(
		_ closureExpression: ClosureExprSyntax)
		throws -> Expression
	{
		guard let typeName = closureExpression.getType(fromList: self.expressionTypes) else {
			return try errorExpression(
				forASTNode: Syntax(closureExpression),
				withMessage: "Unable to get closure type")
		}

		let parameters: MutableList<LabeledType> = []

		// If there are parameters
		if let signature = closureExpression.signature,
			let inputParameters = signature.input
		{
			// Get the input parameter types (e.g. ["Any", "Any"] from "((Any, Any) -> Any)")
			var closureType = typeName
			while Utilities.isInEnvelopingParentheses(closureType) {
				closureType = String(closureType.dropFirst().dropLast())
			}

			let inputAndOutputTypes = Utilities.splitTypeList(closureType, separators: ["->"])
			var inputType = inputAndOutputTypes[0]

			if inputType.hasSuffix(" throws") {
				inputType = String(inputType.dropLast(" throws".count))
			}

			let inputTypes = Utilities.splitTypeList(
				String(inputType.dropFirst().dropLast()),
				separators: [","])

			// Get the parameters
			let cleanInputParameters: List<String>
			if inputParameters.children.allSatisfy({ $0.is(ClosureParamSyntax.self) }) {
				cleanInputParameters = List(inputParameters.children).map {
						$0.as(ClosureParamSyntax.self)!.name.text
					}
			}
			else if let parameterList =
				inputParameters.children.first(where: { $0.is(FunctionParameterListSyntax.self) }),
				let castedParameterList = parameterList.as(FunctionParameterListSyntax.self)
			{
				cleanInputParameters = List(castedParameterList)
					.map { $0.firstName?.text ?? $0.secondName?.text ?? "_" }
			}
			else {
				return try errorExpression(
				forASTNode: Syntax(inputParameters),
				withMessage: "Unable to convert closure parameters")
			}

			// Ensure we have the same number of parameter labels and types
			guard inputTypes.count == cleanInputParameters.count else {
				return try errorExpression(
					forASTNode: Syntax(inputParameters),
					withMessage: "Unable to convert closure parameters; I have " +
						"\(inputTypes.count) types but \(cleanInputParameters.count) parameters")
			}

			for (parameter, inputType) in zip(cleanInputParameters, inputTypes) {
				parameters.append(LabeledType(label: parameter, typeName: inputType))
			}
		}

		return ClosureExpression(
			range: closureExpression.getRange(inFile: self.sourceFile),
			parameters: parameters,
			statements: try convertStatements(closureExpression.statements),
			typeName: typeName)
	}

	func convertSequenceExpression(
		_ sequenceExpression: SequenceExprSyntax)
		throws -> Expression
	{
		return try convertSequenceExpression(
			sequenceExpression,
			limitedToElements: List(sequenceExpression.elements))
	}

	/// Sequence expressions present a series of expressions connected by operators. This method
	/// uses the `operatorInformation` array to determine which operators to evaluate first,
	/// segmenting the expressions array apropriately and translating the segments recursively.
	///
	/// There are a few edge cases to this:
	/// - Assignment operators are dealt with before this method is called, since they have to be
	/// turned into a `Statement`. This can be done because they have the lowest precedence.
	/// - Ternary operators are incorrectly interpreted by SwiftSyntax. This can cause expressions
	/// like `a == b ? c : d == e` to become `a == (b ? c : d) == e` instead of
	/// `(a == b) ? c : (d == e)` like they should. To avoid that, ternary expressions are
	/// deconstructed and evaluated before all others. This can be done because they have the second
	/// lowest precedence (only after assignments).
	/// - The `as` operator's right expression stays inside the `AsExprSyntax` itself, instead of
	/// outside it, resulting in an even number of expressions.
	///
	private func convertSequenceExpression(
		_ sequenceExpression: SequenceExprSyntax,
		limitedToElements elements: List<ExprSyntax>)
	throws -> Expression
	{
		if elements.isEmpty {
			return try errorExpression(
				forASTNode: Syntax(sequenceExpression),
				withMessage: "Attempting to convert an empty section of the sequence expression")
		}
		else if elements.count == 1, let onlyExpression = elements.first {
			return try convertExpression(onlyExpression)
		}

		let range: SourceFileRange?
		if let rangeStart = elements.first?.getRange(inFile: self.sourceFile),
			let rangeEnd = elements.last?.getRange(inFile: self.sourceFile)
		{
			range = SourceFileRange(start: rangeStart.start, end: rangeEnd.end)
		}
		else {
			range = nil
		}

		// Ternary expressions should be treated first, as they have the lowest precedence. This is
		// convenient because SwiftSyntax can handle them incorrectly, turning `a == b ? c : d == e`
		// into `a == (b ? c : d) == e` instead of `(a == b) ? c : (d == e)`
		if let ternaryExpressionIndex =
				elements.firstIndex(where: { $0.is(TernaryExprSyntax.self) }),
			let ternaryExpression = elements[ternaryExpressionIndex].as(TernaryExprSyntax.self)
		{
			let leftHalf = elements.dropLast(elements.count - ternaryExpressionIndex)
				.toMutableList()
			leftHalf.append(ternaryExpression.conditionExpression)

			let rightHalf: MutableList = [ternaryExpression.secondChoice]
			let incompleteRightHalf = elements.dropFirst(ternaryExpressionIndex + 1)
			rightHalf.append(contentsOf: incompleteRightHalf)

			let leftConversion = try convertSequenceExpression(
				sequenceExpression,
				limitedToElements: leftHalf)
			let rightConversion = try convertSequenceExpression(
				sequenceExpression,
				limitedToElements: rightHalf)
			let middleConversion = try convertExpression(ternaryExpression.firstChoice)

			return IfExpression(
				range: range,
				condition: leftConversion,
				trueExpression: middleConversion,
				falseExpression: rightConversion)
		}

		// If all remaining operators have higher precedence than the ternary operator
		let lowestPrecedenceOperatorIndex = getIndexOfLowestPrecedenceOperator(
			forSequenceExpression: sequenceExpression,
			withElements: elements)

		if let index = lowestPrecedenceOperatorIndex {
			if let operatorSyntax = elements[index].as(BinaryOperatorExprSyntax.self) {
				let leftHalf = try convertSequenceExpression(
					sequenceExpression,
					limitedToElements: elements.dropLast(elements.count - index))
				let rightHalf = try convertSequenceExpression(
					sequenceExpression,
					limitedToElements: elements.dropFirst(index + 1))
				let operatorString = operatorSyntax.operatorToken.text

				return BinaryOperatorExpression(
					range: range,
					leftExpression: leftHalf,
					rightExpression: rightHalf,
					operatorSymbol: operatorString,
					typeName: nil)
			}
			else if let asSyntax = elements[index].as(AsExprSyntax.self) {
				if index != (elements.count - 1) {
					return try errorExpression(
						forASTNode: Syntax(sequenceExpression),
						withMessage: "Unexpected operators after \"as\" cast")
				}

				let leftHalf = try convertSequenceExpression(
					sequenceExpression,
					limitedToElements: elements.dropLast(elements.count - index))
				let typeName = try convertType(asSyntax.typeName)

				let expressionType: String
				let operatorString: String
				if let token = asSyntax.questionOrExclamationMark, token.text == "?" {
					operatorString = "as?"
					expressionType = typeName + "?"
				}
				else {
					operatorString = "as"
					expressionType = typeName
				}

				return BinaryOperatorExpression(
					range: range,
					leftExpression: leftHalf,
					rightExpression: TypeExpression(
						range: asSyntax.getRange(inFile: self.sourceFile),
						typeName: typeName),
					operatorSymbol: operatorString,
					typeName: expressionType)
			}
		}

		return try errorExpression(
			forASTNode: Syntax(sequenceExpression),
			withMessage: "Unable to translate sequence expression")
	}

	/// Looks for operators in the given elements, using their information based on the
	/// `operatorInformation` array. Returns the index of the one with the lowest precedence, or
	/// `nil` something goes wrong (e.g. the array is empty, the algorithm can't find an operator
	/// it expected to find, etc).
	private func getIndexOfLowestPrecedenceOperator(
		forSequenceExpression sequenceExpression: SequenceExprSyntax,
		withElements elements: List<ExprSyntax>)
		-> Int?
	{
		let startingPrecedence = Int.max
		var chosenOperatorPrecedence = startingPrecedence
		var chosenIndexInSequence: Int?
		for (currentIndex, currentElement) in elements.enumerated() {
			// Get this operator's information
			let currentOperatorInformation: OperatorInformation
			let currentOperatorPrecedence: Int
			if let binaryOperator = currentElement.as(BinaryOperatorExprSyntax.self) {
				if let precedence = operatorInformation.firstIndex(
					where: { $0.operator == binaryOperator.operatorToken.text })
				{
					// If it's an existing operator
					currentOperatorInformation = operatorInformation[precedence]
					currentOperatorPrecedence = precedence
				}
				else {
					// TODO: Raise warning later (here it might be raised more than once)
					// If it's an unknown operator, assume it has default precedence
					if let precedence = operatorInformation.firstIndex(
						where: { $0.operator == "unknown" })
					{
						currentOperatorInformation = operatorInformation[precedence]
						currentOperatorPrecedence = precedence
					}
					else {
						return nil
					}
				}
			}
			else if currentElement.is(AsExprSyntax.self) {
				if let precedence = operatorInformation.firstIndex(where: { $0.operator == "as" }) {
					currentOperatorInformation = operatorInformation[precedence]
					currentOperatorPrecedence = precedence
				}
				else {
					return nil
				}
			}
			else {
				continue
			}

			// If we found an operator with a lower precedence than the chosen one
			if currentOperatorPrecedence < chosenOperatorPrecedence {
				// Choose this one instead
				chosenOperatorPrecedence = currentOperatorPrecedence
				chosenIndexInSequence = currentIndex
			}
			else if currentOperatorPrecedence == chosenOperatorPrecedence {
				// If we found an operator with the same precedence, see if its
				// associativity is .left or .right
				switch currentOperatorInformation.associativity {
				case .left:
					// Do the right one first so the left one stays together
					chosenOperatorPrecedence = currentOperatorPrecedence
					chosenIndexInSequence = currentIndex
				case .right:
					// Do the left one first so the right one stays together
					break
				case .none:
					// Should never happen
					Compiler.handleWarning(
						message: "Found two operators " +
							"( '\(currentOperatorInformation.operator)' ) with the same " +
							"precedence but no associativity",
						ast: sequenceExpression.toPrintableTree(),
						sourceFile: self.sourceFile,
						sourceFileRange: sequenceExpression
							.getRange(inFile: self.sourceFile))
					break
				}
			}
			else {
				// If we found an operator with higher precedence, ignore it.
			}
		}

		return chosenIndexInSequence
	}

	/// Can be either `object` `.` `member` or `.` `member`. The latter case is implicitly a
	/// `MyType` `.` `member`, and the `MyType` can be obtained by searching for the type of the `.`
	/// token, which will be `MyType.Type`
	func convertMemberAccessExpression(
		_ memberAccessExpression: MemberAccessExprSyntax)
		throws -> Expression
	{
		// Get information for the right side
		guard let memberToken = memberAccessExpression.lastToken,
			let memberType = memberAccessExpression.getType(fromList: self.expressionTypes) else
		{
			return try errorExpression(
				forASTNode: Syntax(memberAccessExpression),
				withMessage: "Failed to convert right side in member access expression")
		}

		let rightSideText = memberToken.text

		// Get information for the left side
		let leftExpression: Expression

		// If it's an `expression` `.` `token`
		if let expressionSyntax = memberAccessExpression.children.first?.as(ExprSyntax.self)
		{
			leftExpression = try convertExpression(expressionSyntax)
		}
		else if let leftType =
				memberAccessExpression.dot.getType(fromList: self.expressionTypes),
			leftType.hasSuffix(".Type")
		{
			// If it's an `.` `token`
			leftExpression = TypeExpression(
				range: memberAccessExpression.dot.getRange(inFile: self.sourceFile),
				typeName: String(leftType.dropLast(".Type".count)))
		}
		else {
			return try errorExpression(
				forASTNode: Syntax(memberAccessExpression),
				withMessage: "Failed to convert left side in member access expression")
		}

		return DotExpression(
			range: memberAccessExpression.getRange(inFile: self.sourceFile),
			leftExpression: leftExpression,
			rightExpression: DeclarationReferenceExpression(
				range: memberToken.getRange(inFile: self.sourceFile),
				identifier: rightSideText,
				typeName: memberType,
				isStandardLibrary: false,
				isImplicit: false))
	}

	func convertDictionaryLiteralExpression(
		_ dictionaryExpression: DictionaryExprSyntax)
		throws -> Expression
	{
		// `[` `elements` `]`
		guard let typeName = dictionaryExpression.getType(fromList: self.expressionTypes) else {
			return try errorExpression(
				forASTNode: Syntax(dictionaryExpression),
				withMessage: "Unable to get dictionary type from SourceKit")
		}

		let keys: MutableList<Expression> = []
		let values: MutableList<Expression> = []

		// If the dictionary isn't empty
		if dictionaryExpression.children.count == 3,
			let elements =
				List(dictionaryExpression.children)[1].as(DictionaryElementListSyntax.self)
		{
			for dictionaryElement in elements {
				try keys.append(convertExpression(dictionaryElement.keyExpression))
				try values.append(convertExpression(dictionaryElement.valueExpression))
			}
		}

		return DictionaryExpression(
			range: dictionaryExpression.getRange(inFile: self.sourceFile),
			keys: keys,
			values: values,
			typeName: typeName)
	}

	func convertArrayLiteralExpression(
		_ arrayExpression: ArrayExprSyntax)
		throws -> Expression
	{
		guard let typeName = arrayExpression.getType(fromList: self.expressionTypes) else {
			return try errorExpression(
				forASTNode: Syntax(arrayExpression),
				withMessage: "Unable to get array type from SourceKit")
		}

		let elements: MutableList<Expression> = try MutableList(arrayExpression.elements.map {
			try convertExpression($0.expression)
		})

		return ArrayExpression(
			range: arrayExpression.getRange(inFile: self.sourceFile),
			elements: elements,
			typeName: typeName)
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
		//  Get the type of the call's tuple
		let tupleTypeName: String?
		if let leftParenthesesPosition = functionCallExpression.leftParen?
				.positionAfterSkippingLeadingTrivia.utf8Offset,
			let rightParenthesesPosition = functionCallExpression.rightParen?
				.positionAfterSkippingLeadingTrivia.utf8Offset
		{
			let tupleStartPosition = leftParenthesesPosition
			let tupleLength = rightParenthesesPosition - leftParenthesesPosition + 1
			let maybeTupleType = self.expressionTypes.first(where: {
				$0.offset == tupleStartPosition && $0.length == tupleLength
			})
			if let tupleType = maybeTupleType {
				tupleTypeName = tupleType.typeName
			}
			else {
				tupleTypeName = nil
			}
		}
		else {
			tupleTypeName = nil
		}

		let functionExpression = functionCallExpression.calledExpression
		let functionExpressionTranslation = try convertExpression(functionExpression)
		let tupleExpression = try convertTupleExpressionElementList(
			functionCallExpression.argumentList,
			withType: tupleTypeName)

		if let trailingClosureSyntax = functionCallExpression.trailingClosure {
			let closureExpression = try convertClosureExpression(trailingClosureSyntax)
			tupleExpression.pairs.append(LabeledExpression(
				label: nil,
				expression: closureExpression))
		}

		return CallExpression(
			range: functionCallExpression.getRange(inFile: self.sourceFile),
			function: functionExpressionTranslation,
			parameters: tupleExpression,
			typeName: functionCallExpression.getType(fromList: self.expressionTypes))
	}

	/// The `convertFunctionCallExpression` method assumes this returns something that can be put in
	/// a `CallExpression`, like a `TupleExpression` or a `TupleShuffleExpression`.
	/// The type has to be passed in because SourceKit needs the parentheses to determine the tuple
	/// type, and the type list doesn't include them.
	func convertTupleExpressionElementList(
		_ tupleExprElementListSyntax: TupleExprElementListSyntax,
		withType tupleType: String?)
		throws -> TupleExpression
	{
		let labeledTypes: List<(String?, String)>?
		if let tupleType = tupleType {
			let tupleTypeWithoutParentheses = String(tupleType.dropFirst().dropLast())
			let tupleTypeComponents = Utilities.splitTypeList(
				tupleTypeWithoutParentheses,
				separators: [","])
			labeledTypes = tupleTypeComponents.map { component -> (String?, String) in
				let labelAndType = Utilities.splitTypeList(component, separators: [":"])
				if labelAndType.count >= 2 {
					let label = labelAndType[0]
					let type = labelAndType.dropFirst().joined(separator: ":")
					return (label, type)
				}
				else {
					let type = labelAndType[0]
					return (nil, type)
				}
			}
		}
		else {
			labeledTypes = nil
		}

		let elements = List(tupleExprElementListSyntax)
		let pairs: MutableList<LabeledExpression> = []

		for tupleExpressionElement in elements {
			let label = tupleExpressionElement.label?.text

			let translatedExpression = try convertExpression(tupleExpressionElement.expression)

			// When a variadic parameter is matched to a single expression, the expression's
			// type comes wrapped in an array (e.g. the `_any` in `print(_any)` has type `[Any]`
			// instead of `Any`). Try to detect these cases and remove the array wrap.
			if let typeName = translatedExpression.swiftType {
				let shouldRemoveArrayWrapper = parameter(
					withLabel: label,
					andType: typeName,
					matchesVariadicInTypeList: labeledTypes)
				if shouldRemoveArrayWrapper {
					translatedExpression.swiftType = String(typeName.dropFirst().dropLast())
				}
			}

			pairs.append(LabeledExpression(label: label, expression: translatedExpression))
		}

		return TupleExpression(
			range: tupleExprElementListSyntax.getRange(inFile: self.sourceFile),
			pairs: pairs)
	}

	/// Checks if the parameter with the given label and type matches a variadic parameter in a type
	/// list.
	private func parameter(
		withLabel label: String?,
		andType typeName: String,
		matchesVariadicInTypeList labeledTypes: List<(String?, String)>?)
		-> Bool
	{
		guard let labeledTypes = labeledTypes,
			typeName.hasPrefix("["),
			typeName.hasSuffix("]") else
		{
			return false
		}

		if let label = label {
			if let tupleType = labeledTypes.first(where: { $0.0 == label }),
				tupleType.1.hasSuffix("...")
			{
				// If there's a type with a matching label, we know it's the right one
				return true
			}
		}
		else {
			// If there's only one parameter without a label, we know it's the right one
			let unlabeledTypes = labeledTypes.filter({ $0.0 == nil })
			if unlabeledTypes.count == 1 {
				if unlabeledTypes[0].1.hasSuffix("...") {
					return true
				}
			}
			// If there's more than one parameter without a label, Swift's matching rules
			// probably get more complicated, so that case is unsupported for now
		}

		return false
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

	func convertFloatLiteralExpression(
		_ floatLiteralExpression: FloatLiteralExprSyntax)
		throws -> Expression
	{
		if let typeName = floatLiteralExpression.getType(fromList: self.expressionTypes) {
			if typeName == "Float",
				let floatValue = Float(floatLiteralExpression.floatingDigits.text)
			{
				return LiteralFloatExpression(
					range: floatLiteralExpression.getRange(inFile: self.sourceFile),
					value: floatValue)
			}
			else if typeName == "Double",
				let doubleValue = Double(floatLiteralExpression.floatingDigits.text)
			{
				return LiteralDoubleExpression(
					range: floatLiteralExpression.getRange(inFile: self.sourceFile),
					value: doubleValue)
			}
		}

		return try errorExpression(
			forASTNode: Syntax(floatLiteralExpression),
			withMessage: "Failed to convert float literal expression")
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
			else if typeName == "Float",
				let floatValue = Float(integerLiteralExpression.digits.text)
			{
				return LiteralFloatExpression(
					range: integerLiteralExpression.getRange(inFile: self.sourceFile),
					value: floatValue)
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
			if let typeName = stringLiteralExpression.getType(fromList: self.expressionTypes),
				typeName == "String.Element" || typeName == "Character"
			{
				return LiteralCharacterExpression(
					range: range,
					value: text)
			}
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
		if let dictionaryType = typeSyntax.as(DictionaryTypeSyntax.self) {
			return try "[" + convertType(dictionaryType.keyType) + ":" +
				convertType(dictionaryType.valueType) + "]"
		}
		if let memberType = typeSyntax.as(MemberTypeIdentifierSyntax.self) {
			return try convertType(memberType.baseType) + "." + memberType.name.text
		}
		if let functionType = typeSyntax.as(FunctionTypeSyntax.self) {
			let argumentsType = try functionType.arguments.map {
				try convertType($0.type)
			}.joined(separator: ", ")

			return try "(" + argumentsType + ") -> " +
				convertType(functionType.returnType)
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

/// A sytax that represents a list of elements, e.g. a list of statements or declarations.
protocol SyntaxList: SyntaxProtocol, Sequence where Element: SyntaxElementContainer { }

/// An element wrapper in a list of syntaxes (e.g. a list of declarations or statements).
/// These lists, like `MemberDeclListSyntax` and `CodeBlockItemListSyntax`, usually wrap their
/// elements in these containers. This protocol allows us to use them generically.
protocol SyntaxElementContainer: SyntaxProtocol {
	var element: Syntax { get }
}

extension CodeBlockItemListSyntax: SyntaxList { }

extension CodeBlockItemSyntax: SyntaxElementContainer {
	var element: Syntax {
		return self.item
	}
}

extension MemberDeclListSyntax: SyntaxList { }

extension MemberDeclListItemSyntax: SyntaxElementContainer {
	var element: Syntax {
		return Syntax(self.decl)
	}
}

/// Left associativity means `(a + b + c) == ((a + b) + c)`. None presumably means this operator
/// can't show up more than once in a row.
enum OperatorAssociativity {
	case none
	case left
	case right
}

typealias OperatorInformation = (operator: String, associativity: OperatorAssociativity)

/// Each tuple represents an operator's string an its associativity. This array is ordered inversely
/// by precedence, with higher precedence operators coming last. This means the last operators
/// should be evaluated first, etc. It also means that the index of the operators serves as a
/// stand-in for their precedence, that is, comparing operators' indices is equivalent to comparing
/// their precedences.
///
/// These are infix operators, so they do not include prefix or postfix operators but they do
/// include the ternary operator.
///
/// The "unknown" value is an added placeholder to correspond to unknown operators. It should have
/// Swift's `Default` precedence, and be (arbitrarily) left-associative.
///
/// This information was obtained from
/// https://developer.apple.com/documentation/swift/swift_standard_library/operator_declarations
let operatorInformation: [OperatorInformation] = [
	// Assignment precedence
	("=", .right), ("*=", .right), ("/=", .right), ("%=", .right), ("+=", .right), ("-=", .right),
	("<<=", .right), (">>=", .right), ("&=", .right), ("|=", .right), ("^=", .right),
	// Ternary precedence
	("?:", .right),
	// Default precedence (for custom operators when no precedence is specified)
	("unknown", .left),
	// Logical disjunction precedence
	("||", .left),
	// Logical conjunction precedence
	("&&", .left),
	// Comparison precedence
	("<", .none), ("<=", .none), (">", .none), (">=", .none), ("==", .none), ("!=", .none),
	("===", .none), ("!==", .none), ("~=", .none), (".==", .none), (".!=", .none), (".<", .none),
	(".<=", .none), (".>", .none), (".>=", .none),
	// Nil coalescing precedence
	("??", .right),
	// Casting precedence
	("is", .left), ("as", .left), ("as?", .left), ("as!", .left),
	// Range formation precedence
	("..<", .none), ("...", .none),
	// Addition precedence
	("+", .left), ("-", .left), ("&+", .left), ("&-", .left), ("|", .left), ("^", .left),
	// Multiplication precedence
	("*", .left), ("/", .left), ("%", .left), ("&*", .left), ("&", .left),
	// Bitwise shift precedence
	("<<", .none), (">>", .none),]

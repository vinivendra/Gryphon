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
		Compiler.logStart("🧑‍💻  Calling SourceKit...")

		// Call SourceKitten to get the types
		// TODO: Improve this yaml. SDK paths? Absolute/relative file paths?
		let absolutePath = Utilities.getAbsoultePath(forFile: filePath)
		let sdkPath = try TranspilationContext.getMacOSSDKPath()
		let compiledFilePathsString = context.compiledFiles
			.map { Utilities.getAbsoultePath(forFile: $0) }
			.map { "\"\($0)\"" }
			.joined(separator: ", ")
		let yaml = """
		{
		  key.request: source.request.expression.type,
		  key.compilerargs: [
			\(compiledFilePathsString),
			"-sdk",
			"\(sdkPath)"
		  ],
		  key.sourcefile: "\(absolutePath)"
		}
		"""

		let sourceKitResult: [String: SourceKitRepresentable]
		do {
			let request = Request.yamlRequest(yaml: yaml)
			sourceKitResult = try request.send()
		}
		catch let error {
			Compiler.log("SourceKit YAML:\n\(yaml)")
			throw GryphonError(errorMessage: "Failed to call SourceKit: " +
				"\(error.localizedDescription)")
		}

		let list = sourceKitResult["key.expression_type_list"]
			as! [[String: SourceKitRepresentable]]
		let typeList = List(list.map {
			ExpressionType(
				offset: Int($0["key.expression_offset"]! as! Int64),
				length: Int($0["key.expression_length"]! as! Int64),
				typeName: $0["key.expression_type"]! as! String)
		})

		Compiler.logEnd("✅  Done calling SourceKit.")

		Compiler.logStart("🧑‍💻  Calling SwiftSyntax...")
		// Call SwiftSyntax to get the tree
		let tree = try SyntaxParser.parse(URL(fileURLWithPath: filePath))
		Compiler.logEnd("✅  Done calling SwiftSyntax.")

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
		let statements = try convertBlock(self.syntaxTree)

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

	func convertBlock<Block>(
		_ block: Block)
		throws -> MutableList<Statement>
		where Block: SyntaxListContainer
	{
		let statements = try convertStatements(block.syntaxElements)

		// Parse the ending comments
		let triviaPieces = getLeadingComments(forSyntax: block.endSyntax)
		for comment in triviaPieces {
			switch comment {
			case let .translationComment(comment: translationComment, range: range):
				if let commentValue = translationComment.value {
					if translationComment.key == .insertInMain {
						statements.append(ExpressionStatement(
							range: range,
							expression: LiteralCodeExpression(
								range: range,
								string: commentValue,
								shouldGoToMainFunction: true,
								typeName: nil)))
					}
					else if translationComment.key == .insert {
						statements.append(ExpressionStatement(
							range: range,
							expression: LiteralCodeExpression(
								range: range,
								string: commentValue,
								shouldGoToMainFunction: false,
								typeName: nil)))
					}
					else if translationComment.key == .output {
						if let fileExtension = Utilities.getExtension(of: commentValue),
							(fileExtension == .swiftAST ||
							 fileExtension == .gryphonASTRaw ||
							 fileExtension == .gryphonAST ||
							 fileExtension == .kt)
						{
							outputFileMap[fileExtension] = translationComment.value
						}
						else {
							Compiler.handleWarning(
								message: "Unsupported output file extension in " +
									"\"\(commentValue)\". Did you mean to use \".kt\"?",
								sourceFile: sourceFile,
								sourceFileRange: range)
						}
					}
				}
			case let .normalComment(comment: normalComment):
				statements.append(normalComment)
			}
		}

		return statements
	}

	/// Converts a list of statements. Ignores possible trivia at the end, since the list doesn't
	/// include braces (and the end trivia is associated with the closing brace).
	func convertStatements<Body>(
		_ statements: Body)
		throws -> MutableList<Statement>
		where Body: SyntaxList
	{
		let result: MutableList<Statement> = []

		for statement in statements {
			let item: Syntax = statement.element

			// Parse the statement's leading comments
			var shouldIgnoreStatement = false
			let leadingComments = getLeadingComments(forSyntax: Syntax(statement))
			for comment in leadingComments {
				switch comment {
				case let .translationComment(comment: translationComment, range: range):
					if let commentValue = translationComment.value {
						if translationComment.key == .insertInMain {
							result.append(ExpressionStatement(
								range: range,
								expression: LiteralCodeExpression(
									range: range,
									string: commentValue,
									shouldGoToMainFunction: true,
									typeName: nil)))
						}
						else if translationComment.key == .insert {
							result.append(ExpressionStatement(
								range: range,
								expression: LiteralCodeExpression(
									range: range,
									string: commentValue,
									shouldGoToMainFunction: false,
									typeName: nil)))
						}
						else if translationComment.key == .output {
							if let fileExtension = Utilities.getExtension(of: commentValue),
								(fileExtension == .swiftAST ||
								 fileExtension == .gryphonASTRaw ||
								 fileExtension == .gryphonAST ||
								 fileExtension == .kt)
							{
								outputFileMap[fileExtension] = translationComment.value
							}
							else {
								Compiler.handleWarning(
									message: "Unsupported output file extension in " +
										"\"\(commentValue)\". Did you mean to use \".kt\"?",
									sourceFile: sourceFile,
									sourceFileRange: range)
							}
						}
					}
					else if translationComment.key == .ignore {
						// TODO: add a warning for translation comments at the end of lines
						shouldIgnoreStatement = true
					}
				case let .normalComment(comment: normalComment):
					result.append(normalComment)
				}
			}

			if shouldIgnoreStatement {
				continue
			}

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
						lastTopOfFileCommentLine >= range.lineStart - 1
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

	private enum Comment {
		case translationComment(comment: SourceFile.TranslationComment, range: SourceFileRange)
		case normalComment(comment: CommentStatement)
	}

	private func getLeadingComments(
		forSyntax syntax: Syntax,
		withKey key: SourceFile.CommentKey)
		-> List<SourceFile.TranslationComment>
	{
		let leadingComments = getLeadingComments(forSyntax: syntax)
		return leadingComments.compactMap { comment -> SourceFile.TranslationComment? in
				if case let .translationComment(comment: translationComment, range: _)
						= comment,
					translationComment.key == key
				{
					return translationComment
				}
				else {
					return nil
				}
			}
	}

	private func getLeadingComments(
		forSyntax syntax: Syntax)
		-> MutableList<Comment>
	{
		let result: MutableList<Comment> = []

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

				if let commentString = maybeCommentString {
					let cleanComment = commentString.trimmingWhitespaces()

					let range = SourceFileRange.getRange(
						withStartOffset: startOffset,
						withEndOffset: endOffset - 1, // Inclusive end
						inFile: self.sourceFile)

					if let translationComment =
						SourceFile.getTranslationCommentFromString(cleanComment)
					{
						result.append(.translationComment(
							comment: translationComment,
							range: range))
					}
					else {
						let normalComment = CommentStatement(
							range: range,
							value: commentString)
						result.append(.normalComment(comment: normalComment))
					}
				}

				startOffset = endOffset
			}
		}

		return result
	}

	// MARK: - Statements
	func convertStatement(_ statement: StmtSyntax) throws -> List<Statement> {
		if let breakStatement = statement.as(BreakStmtSyntax.self) {
			return [BreakStatement(range: breakStatement.getRange(inFile: self.sourceFile))]
		}
		if let continueStatement = statement.as(ContinueStmtSyntax.self) {
			return [ContinueStatement(range: continueStatement.getRange(inFile: self.sourceFile))]
		}
		if let throwStatement = statement.as(ThrowStmtSyntax.self) {
			return [ThrowStatement(
				range: throwStatement.getRange(inFile: self.sourceFile),
				expression: try convertExpression(throwStatement.expression))]
		}
		if let returnStatement = statement.as(ReturnStmtSyntax.self) {
			return try [convertReturnStatement(returnStatement)]
		}
		if let ifStatement: IfLikeSyntax =
			statement.as(IfStmtSyntax.self) ??
			statement.as(GuardStmtSyntax.self)
		{
			return try [convertIfStatement(ifStatement)]
		}
		if let forStatement = statement.as(ForInStmtSyntax.self) {
			return try [convertForStatement(forStatement)]
		}
		if let whileStatement = statement.as(WhileStmtSyntax.self) {
			return try [convertWhileStatement(whileStatement)]
		}
		if let switchStatement = statement.as(SwitchStmtSyntax.self) {
			return try [convertSwitchStatement(switchStatement)]
		}
		if let doStatement = statement.as(DoStmtSyntax.self) {
			return try convertDoStatement(doStatement)
		}

		return try [errorStatement(
			forASTNode: Syntax(statement),
			withMessage: "Unknown statement")]
	}

	func convertDoStatement(
		_ doStatement: DoStmtSyntax)
		throws -> MutableList<Statement>
	{
		let result: MutableList<Statement> = []

		result.append(DoStatement(
			range: doStatement.getRange(inFile: self.sourceFile),
			statements: try convertBlock(doStatement.body)))

		if let catchClauses = doStatement.catchClauses {
			for catchClause in catchClauses {
				let variableDeclaration: VariableDeclaration?
				if let pattern = catchClause.pattern {
					// If a variable is being declared
					if let valueBindingPattern =
							pattern.as(ValueBindingPatternSyntax.self),
						let valuePattern =
							valueBindingPattern.valuePattern.as(IdentifierPatternSyntax.self)
					{
						// If the declaration is supported
						variableDeclaration = VariableDeclaration(
							range: pattern.getRange(inFile: self.sourceFile),
							identifier: valuePattern.identifier.text,
							typeAnnotation: "Error",
							expression: nil,
							getter: nil,
							setter: nil,
							access: nil,
							isOpen: false,
							isLet: valueBindingPattern.letOrVarKeyword.text == "let",
							isImplicit: false,
							isStatic: false,
							extendsType: nil,
							annotations: [])
					}
					else {
						// If the declaration is not supported
						try result.append(errorStatement(
							forASTNode: Syntax(pattern),
							withMessage: "Unsupported pattern in catch clause"))
						continue
					}
				}
				else {
					// If no variables are being declared
					variableDeclaration = nil
				}

				result.append(CatchStatement(
					range: catchClause.getRange(inFile: self.sourceFile),
					variableDeclaration: variableDeclaration,
					statements: try convertBlock(catchClause.body)))
			}
		}

		return result
	}

	func convertSwitchStatement(
		_ switchStatement: SwitchStmtSyntax)
		throws -> Statement
	{
		let switchExpression = try convertExpression(switchStatement.expression)

		let cases: MutableList<SwitchCase> = []
		for syntax in switchStatement.cases {
			let statements: MutableList<Statement> = []

			if let switchCase = syntax.as(SwitchCaseSyntax.self) {
				let expressions: MutableList<Expression>
				if let label = switchCase.label.as(SwitchCaseLabelSyntax.self) {
					// If it's a case with an expression
					expressions = try MutableList(label.caseItems.map { item -> Expression in
						if let expression = item.pattern.as(ExpressionPatternSyntax.self) {
							// If it's a simple case

							// FIXME: SourceKit doesn't include info on `.a` anywhere, apparently
							if let memberExpression =
									expression.expression.as(MemberAccessExprSyntax.self),
								memberExpression.base == nil,
								let typeName = switchExpression.swiftType
							{
								// If it's a `.a`, assume the type is the same as the switch
								// expression's
								return try convertMemberAccessExpression(
									memberExpression,
									typeName: typeName)
							}
							else {
								return try convertExpression(expression.expression)
							}
						}
						else if let pattern = item.pattern.as(ValueBindingPatternSyntax.self) {
							// If it's a case let
							let caseLetResult = try convertCaseLet(
								pattern: pattern,
								patternExpression: switchExpression)

							statements.append(contentsOf:
								caseLetResult.variables.forceCast(to: MutableList<Statement>.self))

							guard caseLetResult.conditions.count == 1,
								let onlyCondition = caseLetResult.conditions.first else
							{
								if caseLetResult.conditions.count == 0 {
									return try errorExpression(
										forASTNode: Syntax(item),
										withMessage: "Expected case let to yield at least one " +
											"expression")
								}
								else {
									return try errorExpression(
										forASTNode: Syntax(item),
										withMessage: "Case let's with expressions are not " +
											"supported in Kotlin.")
								}
							}

							return onlyCondition
						}
						else {
							return try errorExpression(
								forASTNode: Syntax(item),
								withMessage: "Unsupported switch case item")
						}
					})
				}
				else if switchCase.label.is(SwitchDefaultLabelSyntax.self) {
					// If it's a `default:` label
					expressions = []
				}
				else {
					expressions = [try errorExpression(
						forASTNode: switchCase.label,
						withMessage: "Unsupported switch case label")]
				}

				// Add the explicit statements after possible variable declarations derived from
				// `case let`
				// TODO: Check for comments at the end
				try statements.append(contentsOf: convertStatements(switchCase.statements))

				cases.append(SwitchCase(
					expressions: expressions,
					statements: statements))
			}
			else {
				let expression = try errorExpression(
					forASTNode: syntax,
					withMessage: "Unsupported switch case")
				cases.append(SwitchCase(
					expressions: [expression],
					statements: []))
			}
		}

		return SwitchStatement(
			range: switchStatement.getRange(inFile: self.sourceFile),
			convertsToExpression: nil,
			expression: switchExpression,
			cases: cases)
	}

	func convertWhileStatement(
		_ whileStatement: WhileStmtSyntax)
		throws -> Statement
	{
		let conditions = whileStatement.conditions

		guard conditions.count == 1,
			let onlyCondition = conditions.first,
			let onlyExpression = onlyCondition.condition.as(ExprSyntax.self) else
		{
			return try errorStatement(
				forASTNode: Syntax(whileStatement),
				withMessage: "Expected while statement to have one expression as its condition")
		}

		let expression = try convertExpression(onlyExpression)
		let statements = try convertBlock(whileStatement.body)

		return WhileStatement(
			range: whileStatement.getRange(inFile: self.sourceFile),
			expression: expression,
			statements: statements)
	}

	func convertForStatement(
		_ forStatement: ForInStmtSyntax)
		throws -> Statement
	{
		let variable = try convertPatternExpression(forStatement.pattern)
		let collection = try convertExpression(forStatement.sequenceExpr)
		let statements = try convertBlock(forStatement.body)

		return ForEachStatement(
			range: forStatement.getRange(inFile: self.sourceFile),
			collection: collection,
			variable: variable,
			statements: statements)
	}

	func convertIfStatement(
		_ ifStatement: IfLikeSyntax)
		throws -> IfStatement
	{
		let statements: MutableList<Statement> = []
		let conditions: MutableList<IfStatement.IfCondition> = []
		for ifCondition in ifStatement.ifConditions {
			if let expressionSyntax = ifCondition.condition.as(ExprSyntax.self) {
				// if (expr)
				let expression = try convertExpression(expressionSyntax)
				conditions.append(.condition(expression: expression))
				continue
			}
			else if let optionalBinding =
					ifCondition.condition.as(OptionalBindingConditionSyntax.self),
				let identifier = optionalBinding.pattern.getText()
			{
				// if let
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
				continue
			}
			else if let matchingPattern =
					ifCondition.condition.as(MatchingPatternConditionSyntax.self),
				let expressionPattern = matchingPattern.pattern.as(ExpressionPatternSyntax.self),
				let enumExpression = expressionPattern.expression.as(MemberAccessExprSyntax.self)
			{
				// if case
				let leftExpression = matchingPattern.initializer.value

				// The enumExpression may come as `.a1`, without direct way of knowing waht to place
				// before the dot. Try to guess it from the type of the pattern expression.
				let patternExpression = try convertExpression(matchingPattern.initializer.value)

				// TODO: test a case where the left expression is present
				if let enumType = patternExpression.swiftType {
					let dotExpression = try convertMemberAccessExpression(
						enumExpression,
						typeName: enumType)
					if let typeName = dotExpressionToString(dotExpression) {
						conditions.append(.condition(expression: BinaryOperatorExpression(
							range: ifCondition.getRange(inFile: self.sourceFile),
							leftExpression: try convertExpression(leftExpression),
							rightExpression: TypeExpression(
								range: enumExpression.getRange(inFile: self.sourceFile),
								typeName: typeName),
							operatorSymbol: "is",
							typeName: "Bool")))
						continue
					}
				}
			}
			else if let matchingPattern =
					ifCondition.condition.as(MatchingPatternConditionSyntax.self),
				let valueBindingPattern =
					matchingPattern.pattern.as(ValueBindingPatternSyntax.self)
			{
				// If case let
				let patternExpression = try convertExpression(matchingPattern.initializer.value)
				let caseLetResult = try convertCaseLet(
					pattern: valueBindingPattern,
					patternExpression: patternExpression)
				conditions.append(contentsOf:
					caseLetResult.conditions.map { .condition(expression: $0) })
				statements.append(contentsOf:
					caseLetResult.variables.forceCast(to: MutableList<Statement>.self))
				continue
			}

			// If we didn't `continue` before this point then this isn't a known if condition
			try conditions.append(.condition(expression: errorExpression(
				forASTNode: Syntax(ifCondition),
				withMessage: "Unable to translate if condition")))
		}

		statements.append(contentsOf: try convertBlock(ifStatement.statements))

		let elseStatement: IfStatement?
		if let elseIfSyntax = ifStatement.children.last?.as(IfStmtSyntax.self) {
			elseStatement = try convertIfStatement(elseIfSyntax)
		}
		else if let elseBlock = ifStatement.elseBlock {
			let elseBodyStatements = try convertBlock(elseBlock)
			elseStatement = IfStatement(
				range: elseBlock.getRange(inFile: self.sourceFile),
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
			isGuard: ifStatement.isGuard)
	}

	/// The result of translating a case let like `A.a(b: c, d: 0)`
	private struct CaseLetResult {
		/// The conditions derived from this, like `exp is A.a` and `exp.d == 0`
		let conditions: MutableList<Expression>
		/// The variable declarations that unwrap the case let, like `let c = exp.b`
		let variables: MutableList<VariableDeclaration>
	}

	/// Translates a case let like `A.a(b: c) = myEnum`. The `pattern` parameter is the `A.a(b: c)`,
	/// and the `expression` parameter is the `myEnum`.
	private func convertCaseLet(
		pattern: ValueBindingPatternSyntax,
		patternExpression: Expression)
		throws -> CaseLetResult
	{
		let conditions: MutableList<Expression> = []
		let variableDeclarations: MutableList<VariableDeclaration> = []

		if let valuePattern =
				pattern.valuePattern.as(ExpressionPatternSyntax.self),
			let callExpression =
				valuePattern.expression.as(FunctionCallExprSyntax.self),
			let calledExpression =
				callExpression.calledExpression.as(MemberAccessExprSyntax.self)
		{
			// TODO: test a case where the left expression is present
			if let enumType = patternExpression.swiftType {
				let dotExpression = try convertMemberAccessExpression(
					calledExpression,
					typeName: enumType)
				if let typeName = dotExpressionToString(dotExpression) {
					conditions.append(BinaryOperatorExpression(
						range: pattern.getRange(inFile: self.sourceFile),
						leftExpression: patternExpression,
						rightExpression: TypeExpression(
							range: calledExpression.getRange(inFile: self.sourceFile),
							typeName: typeName),
						operatorSymbol: "is",
						typeName: "Bool"))

					for argument in callExpression.argumentList {
						if let label = argument.label {
							// Create the enum member expression (e.g. `A.b`)
							let range = argument.getRange(inFile: self.sourceFile)
							let enumMember = DeclarationReferenceExpression(
								range: range,
								identifier: label.text,
								typeName: typeName,
								isStandardLibrary: false,
								isImplicit: false)
							let enumExpression = DotExpression(
								range: range,
								leftExpression: patternExpression,
								rightExpression: enumMember)

							if let pattern =
								argument.expression.as(UnresolvedPatternExprSyntax.self),
								let identifierPattern =
								pattern.pattern.as(IdentifierPatternSyntax.self)
							{
								// If we're declaring a variable, e.g. the `bar` in
								// `A.b(foo: bar)`
								variableDeclarations.append(VariableDeclaration(
									range: argument.getRange(inFile: self.sourceFile),
									identifier: identifierPattern.identifier.text,
									typeAnnotation: nil,
									expression: enumExpression,
									getter: nil,
									setter: nil,
									access: nil,
									isOpen: false,
									isLet: true,
									isImplicit: false,
									isStatic: false,
									extendsType: nil,
									annotations: []))
							}
							else if argument.expression.is(DiscardAssignmentExprSyntax.self) {
								// `A.b(foo: _)`, just ignore it
							}
							else {
								// If we're comparing a value, e.g. the `"bar"` in
								// `A.b(foo: "bar")`
								let comparedExpression = try convertExpression(argument.expression)
								conditions.append(BinaryOperatorExpression(
									range: argument.getRange(inFile: self.sourceFile),
									leftExpression: enumExpression,
									rightExpression: comparedExpression,
									operatorSymbol: "==",
									typeName: "Bool"))
							}
						}
					}

					return CaseLetResult(
						conditions: conditions,
						variables: variableDeclarations)
				}
			}
		}

		conditions.append(try errorExpression(
			forASTNode: Syntax(pattern),
			withMessage: "Unable to convert case let pattern."))
		return CaseLetResult(
			conditions: conditions,
			variables: variableDeclarations)
	}

	/// Takes an expression like `A.B.C` and returns it as a string ("A.B.C"). Returns `nil` if any
	/// expressions in the dot chain aren't declaration references or type expressions.
	private func dotExpressionToString(_ expression: Expression) -> String? {
		if let typeExpression = expression as? TypeExpression {
			return typeExpression.typeName
		}
		else if let declarationExpression = expression as? DeclarationReferenceExpression {
			return declarationExpression.identifier
		}
		else if let dotExpression = expression as? DotExpression {
			guard let rightString = dotExpressionToString(dotExpression.rightExpression),
				let leftString = dotExpressionToString(dotExpression.leftExpression) else
			{
				return nil
			}

			return leftString + "." + rightString
		}
		else {
			return nil
		}
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
		if let extensionDeclaration = declaration.as(ExtensionDeclSyntax.self) {
			return try [convertExtensionDeclaration(extensionDeclaration)]
		}
		if let ifConfigDeclaration = declaration.as(IfConfigDeclSyntax.self) {
			return try convertIfConfigDeclaration(ifConfigDeclaration)
		}
		if let protocolDeclaration = declaration.as(ProtocolDeclSyntax.self) {
			return try [convertProtocolDeclaration(protocolDeclaration)]
		}
		if let classDeclaration = declaration.as(ClassDeclSyntax.self) {
			return try [convertClassDeclaration(classDeclaration)]
		}
		if let structDeclaration = declaration.as(StructDeclSyntax.self) {
			return try [convertStructDeclaration(structDeclaration)]
		}
		if let enumDeclaration = declaration.as(EnumDeclSyntax.self) {
			return try [convertEnumDeclaration(enumDeclaration)]
		}
		if let variableDeclaration = declaration.as(VariableDeclSyntax.self) {
			return try convertVariableDeclaration(variableDeclaration)
		}
		if let subscriptDeclaration = declaration.as(SubscriptDeclSyntax.self) {
			return try convertSubscriptDeclaration(subscriptDeclaration)
		}
		if let functionDeclaration: FunctionLikeSyntax =
			declaration.as(FunctionDeclSyntax.self) ??
			declaration.as(InitializerDeclSyntax.self)
		{
			return try [convertFunctionDeclaration(functionDeclaration)]
		}
		if let importDeclaration = declaration.as(ImportDeclSyntax.self) {
			return try [convertImportDeclaration(importDeclaration)]
		}
		if let typealiasDeclaration = declaration.as(TypealiasDeclSyntax.self) {
			return try [convertTypealiasDeclaration(typealiasDeclaration)]
		}

		return try [errorStatement(
			forASTNode: Syntax(declaration),
			withMessage: "Unknown declaration"), ]
	}

	func convertSubscriptDeclaration(
		_ subscriptDeclaration: SubscriptDeclSyntax)
		throws -> MutableList<Statement>
	{
		let result: MutableList<Statement> = []

		let subscriptParameters = try convertParameters(subscriptDeclaration.indices.parameterList)
		let subscriptReturnType = try convertType(subscriptDeclaration.result.returnType)

		if let accessorBlock = subscriptDeclaration.accessor?.as(AccessorBlockSyntax.self) {
			for accessor in accessorBlock.accessors {
				if let maybeCodeBlock =
						accessor.children.first(where: { $0.is(CodeBlockSyntax.self) }),
					let codeBlock = maybeCodeBlock.as(CodeBlockSyntax.self)
				{
					let statements = try convertBlock(codeBlock)

					let prefix = accessor.accessorKind.text

					let parameters: MutableList<FunctionParameter>
					let returnType: String
					if prefix == "get" {
						parameters = subscriptParameters
						returnType = subscriptReturnType
					}
					else {
						parameters = subscriptParameters.appending(FunctionParameter(
							label: "newValue",
							apiLabel: nil,
							typeName: subscriptReturnType,
							value: nil)).toMutableList()
						returnType = "Void"
					}

					let parameterType = parameters.map { $0.typeName }.joined(separator: ", ")
					let functionType = "(\(parameterType)) -> \(returnType)"

					let accessAndAnnotations =
						getAccessAndAnnotations(fromModifiers: subscriptDeclaration.modifiers)

					let annotations = accessAndAnnotations.annotations

					let isOpen: Bool
					if annotations.remove("final") {
						isOpen = false
					}
					else if let access = accessAndAnnotations.access, access == "open" {
						isOpen = true
					}
					else {
						isOpen = !context.defaultsToFinal
					}

					annotations.append("operator")

					result.append(FunctionDeclaration(
						range: accessor.getRange(inFile: self.sourceFile),
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
						annotations: annotations))
				}
				else {
					try result.append(errorStatement(
						forASTNode: Syntax(accessor),
						withMessage: "Unable to get code block in subscript declaration"))
				}
			}
		}
		else {
			try result.append(errorStatement(
				forASTNode: Syntax(subscriptDeclaration),
				withMessage: "Unable to find getters or setters in subscript declaration"))
		}

		return result
	}

	func convertExtensionDeclaration(
		_ extensionDeclaration: ExtensionDeclSyntax)
		throws -> Statement
	{
		// TODO: add tests
		let comments = getLeadingComments(
			forSyntax: Syntax(extensionDeclaration),
			withKey: .generics)

		let syntaxType = try convertType(extensionDeclaration.extendedType)

		let extendedType: String
		if let comment = comments.first, let value = comment.value {
			extendedType = syntaxType + "<\(value)>"
		}
		else {
			extendedType = syntaxType
		}

		return ExtensionDeclaration(
			range: extensionDeclaration.getRange(inFile: self.sourceFile),
			typeName: extendedType,
			members: try convertBlock(extensionDeclaration.members))
	}

	/// Convert `#if GRYPHON`
	func convertIfConfigDeclaration(
		_ ifConfigDeclaration: IfConfigDeclSyntax)
		throws -> MutableList<Statement>
	{
		let result: MutableList<Statement> = []

		// Records if we're dealing with `#if GRYPHON` or `#if !GRYPHON`
		var gryphonClauseIsNegated = false

		var nextClauses = ifConfigDeclaration.clauses.dropFirst().makeIterator()
		for clause in ifConfigDeclaration.clauses {
			let nextClause = nextClauses.next()

			let block: CodeBlockItemListSyntax

			// If it's a `#if`
			if let condition = clause.condition {
				if let identifierCondition = condition.as(IdentifierExprSyntax.self),
					identifierCondition.identifier.text == "GRYPHON",
					let conditionBlock = clause.elements.as(CodeBlockItemListSyntax.self)
				{
					// If it's a `#if GRYPHON`
					gryphonClauseIsNegated = false
					block = conditionBlock
				}
				else if let prefixOperatorCondition = condition.as(PrefixOperatorExprSyntax.self),
					let operatorString = prefixOperatorCondition.operatorToken?.text,
					operatorString == "!",
					let identifierCondition =
						prefixOperatorCondition.postfixExpression.as(IdentifierExprSyntax.self),
					identifierCondition.identifier.text == "GRYPHON"
				{
					// If it's a `#if !GRYPHON`
					gryphonClauseIsNegated = true
					continue
				}
				else {
					return try [errorStatement(
						forASTNode: Syntax(clause),
						withMessage: "Unsupported #if declaration; only `#if GRYPHON`, " +
							"`#if !GRYPHON` and `#else` are supported.")]
				}
			}
			else if let conditionBlock = clause.elements.as(CodeBlockItemListSyntax.self) {
				// If it's a `#else`
				if gryphonClauseIsNegated {
					// If there was a `#if !GRYPHON` before, we have to translate the `#else`
					block = conditionBlock
				}
				else {
					continue
				}
			}
			else {
				// If there isn't even a block
				return try [errorStatement(
					forASTNode: Syntax(clause),
					withMessage: "Unsupported #if declaration; only `#if GRYPHON`, " +
						"`#if !GRYPHON` and `#else` are supported.")]
			}

			// Figure out where this block of statements ends
			let endSyntax: Syntax
			if let nextClause = nextClause {
				// If there's another clause after this one
				endSyntax = Syntax(nextClause.poundKeyword)
			}
			else {
				// If this is the last clause
				endSyntax = Syntax(ifConfigDeclaration.poundEndif)
			}

			let container = SomeSyntaxListContainer(
				syntaxElements: block,
				endSyntax: endSyntax)
			try result.append(contentsOf: convertBlock(container))
		}

		return result
	}

	func convertProtocolDeclaration(
		_ protocolDeclaration: ProtocolDeclSyntax)
		throws -> Statement
	{
		let accessAndAnnotations =
			getAccessAndAnnotations(fromModifiers: protocolDeclaration.modifiers)

		// Get annotations from `gryphon annotation` comments
		let annotationComments = getLeadingComments(
			forSyntax: Syntax(protocolDeclaration),
			withKey: .annotation)
		let manualAnnotations = annotationComments.compactMap { $0.value }
		let annotations = accessAndAnnotations.annotations
		annotations.append(contentsOf: manualAnnotations)

		return ProtocolDeclaration(
			range: protocolDeclaration.getRange(inFile: self.sourceFile),
			protocolName: protocolDeclaration.identifier.text,
			access: accessAndAnnotations.access,
			annotations: annotations,
			members: try convertBlock(protocolDeclaration.members))
	}

	func convertEnumDeclaration(
		_ enumDeclaration: EnumDeclSyntax)
		throws -> Statement
	{
		let inheritances = try enumDeclaration.inheritanceClause?.inheritedTypeCollection.map {
				try convertType($0.typeName)
			} ?? []

		let accessAndAnnotations =
			getAccessAndAnnotations(fromModifiers: enumDeclaration.modifiers)
		// Get annotations from `gryphon annotation` comments
		let annotationComments = getLeadingComments(
			forSyntax: Syntax(enumDeclaration),
			withKey: .annotation)
		let manualAnnotations = annotationComments.compactMap { $0.value }
		let annotations = accessAndAnnotations.annotations
		annotations.append(contentsOf: manualAnnotations)

		let (cases, members) = List(enumDeclaration.members.members)
			.separate { $0.element.is(EnumCaseDeclSyntax.self) }

		let elements: MutableList<EnumElement> = []
		for syntax in cases {
			if let caseSyntax = syntax.element.as(EnumCaseDeclSyntax.self) {
				// TODO: add test for `case a, b, c`
				for element in caseSyntax.elements {
					let associatedValues: MutableList<LabeledType>
					if let parameters = element.associatedValue?.parameterList {
						let convertedParameters = try convertParameters(parameters)
						associatedValues = convertedParameters.map {
							LabeledType(
								label: $0.label,
								typeName: $0.typeName)
						}.toMutableList()
					}
					else {
						associatedValues = []
					}

					let rawValue = try element.rawValue.map { try convertExpression($0.value) }

					elements.append(EnumElement(
						name: element.identifier.text,
						associatedValues: associatedValues,
						rawValue: rawValue,
						annotations: []))
				}
			}
			else {
				// Should never happen because of the `is` check above
				return try errorStatement(
					forASTNode: syntax.element,
					withMessage: "Expected enum element to by an EnumCaseDeclSyntax")
			}
		}

		return EnumDeclaration(
			range: enumDeclaration.getRange(inFile: self.sourceFile),
			access: accessAndAnnotations.access,
			enumName: enumDeclaration.identifier.text,
			annotations: annotations,
			inherits: MutableList(inheritances),
			elements: elements,
			members: try convertStatements(members),
			isImplicit: false)
	}

	func convertStructDeclaration(
		_ structDeclaration: StructDeclSyntax)
		throws -> Statement
	{
		let structBaseType = structDeclaration.identifier.text

		// TODO: Support generic classes, etc
		let structName: String
		if let generics = structDeclaration.genericParameterClause?.genericParameterList {
			let genericString = generics.map { $0.name.text }.joined(separator: ", ")
			structName = structBaseType + "<" + genericString + ">"
		}
		else {
			structName = structBaseType
		}

		let inheritances = try structDeclaration.inheritanceClause?.inheritedTypeCollection.map {
				try convertType($0.typeName)
			} ?? []

		let accessAndAnnotations =
			getAccessAndAnnotations(fromModifiers: structDeclaration.modifiers)
		// Get annotations from `gryphon annotation` comments
		let annotationComments = getLeadingComments(
			forSyntax: Syntax(structDeclaration),
			withKey: .annotation)
		let manualAnnotations = annotationComments.compactMap { $0.value }
		let annotations = accessAndAnnotations.annotations
		annotations.append(contentsOf: manualAnnotations)

		return StructDeclaration(
			range: structDeclaration.getRange(inFile: self.sourceFile),
			annotations: annotations,
			structName: structName,
			access: accessAndAnnotations.access,
			inherits: MutableList(inheritances),
			members: try convertBlock(structDeclaration.members))
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
		// Get annotations from `gryphon annotation` comments
		let annotationComments = getLeadingComments(
			forSyntax: Syntax(classDeclaration),
			withKey: .annotation)
		let manualAnnotations = annotationComments.compactMap { $0.value }
		let annotations = accessAndAnnotations.annotations
		annotations.append(contentsOf: manualAnnotations)

		let isOpen: Bool
		if annotations.remove("final") {
			isOpen = false
		}
		else if let access = accessAndAnnotations.access, access == "open" {
			isOpen = true
		}
		else {
			isOpen = !context.defaultsToFinal
		}

		return ClassDeclaration(
			range: classDeclaration.getRange(inFile: self.sourceFile),
			className: classDeclaration.identifier.text,
			annotations: annotations,
			access: accessAndAnnotations.access,
			isOpen: isOpen,
			inherits: MutableList(inheritances),
			members: try convertBlock(classDeclaration.members))
	}

	func convertTypealiasDeclaration(
		_ typealiasDeclaration: TypealiasDeclSyntax)
		throws -> Statement
	{
		guard let typeSyntax = typealiasDeclaration.initializer?.value else {
			return try errorStatement(
				forASTNode: Syntax(typealiasDeclaration),
				withMessage: "Unable to get the type name.")
		}

		let accessAndAnnotations =
			getAccessAndAnnotations(fromModifiers: typealiasDeclaration.modifiers)

		return TypealiasDeclaration(
			range: typealiasDeclaration.getRange(inFile: self.sourceFile),
			identifier: typealiasDeclaration.identifier.text,
			typeName: try convertType(typeSyntax),
			access: accessAndAnnotations.access,
			isImplicit: false)
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
		_ functionLikeDeclaration: FunctionLikeSyntax)
		throws -> Statement
	{
		let prefix = functionLikeDeclaration.prefix

		let parameters: MutableList<FunctionParameter> =
			try convertParameters(functionLikeDeclaration.parameterList)

		let inputType = "(" + parameters
				.map { $0.typeName + ($0.isVariadic ? "..." : "") }
				.joined(separator: ", ") +
			")"

		let returnType: String
		if let returnTypeSyntax = functionLikeDeclaration.returnType {
			returnType = try convertType(returnTypeSyntax)
		}
		else {
			returnType = "Void"
		}

		let functionType = inputType + " -> " + returnType

		let statements: MutableList<Statement>
		if let statementsSyntax = functionLikeDeclaration.statements {
			statements = try convertBlock(statementsSyntax)
		}
		else {
			statements = []
		}

		let accessAndAnnotations =
			getAccessAndAnnotations(fromModifiers: functionLikeDeclaration.modifierList)

		// Get annotations from `gryphon annotation` comments
		let annotationComments = getLeadingComments(
			forSyntax: functionLikeDeclaration.asSyntax,
			withKey: .annotation)
		let manualAnnotations = annotationComments.compactMap { $0.value }
		let annotations = accessAndAnnotations.annotations
		annotations.append(contentsOf: manualAnnotations)

		let isOpen: Bool
		if annotations.remove("final") {
			isOpen = false
		}
		else if let access = accessAndAnnotations.access, access == "open" {
			isOpen = true
		}
		else {
			isOpen = !context.defaultsToFinal
		}

		let generics: MutableList<String>
		if let genericsSyntax = functionLikeDeclaration.generics {
			generics = MutableList(genericsSyntax.map { $0.name.text })
		}
		else {
			generics = []
		}

		if !functionLikeDeclaration.isInitializer {
			let isStatic = accessAndAnnotations.annotations.remove("static")

			return FunctionDeclaration(
				range: functionLikeDeclaration.getRange(inFile: sourceFile),
				prefix: prefix,
				parameters: parameters,
				returnType: returnType,
				functionType: functionType,
				genericTypes: generics,
				isOpen: isOpen,
				isImplicit: false,
				isStatic: isStatic,
				isMutating: false,
				isPure: false,
				isJustProtocolInterface: false,
				extendsType: nil,
				statements: statements,
				access: accessAndAnnotations.access,
				annotations: annotations)
		}
		else {
			return InitializerDeclaration(
				range: functionLikeDeclaration.getRange(inFile: sourceFile),
				parameters: parameters,
				returnType: returnType,
				functionType: functionType,
				genericTypes: generics,
				isOpen: isOpen,
				isImplicit: false,
				isStatic: true,
				isMutating: false,
				isPure: false,
				extendsType: nil,
				statements: statements,
				access: accessAndAnnotations.access,
				annotations: annotations,
				superCall: nil,
				isOptional: functionLikeDeclaration.isOptional)
		}
	}

	/// Parameter tokens: `firstName` `secondName (optional)` `:` `type` `, (optional)`
	func convertParameters(
		_ parameterList: FunctionParameterListSyntax)
		throws -> MutableList<FunctionParameter>
	{
		let result: MutableList<FunctionParameter> = []
		for parameter in parameterList {
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

				let defaultValue: Expression?
				if let defaultExpression = parameter.defaultArgument?.value {
					defaultValue = try convertExpression(defaultExpression)
				}
				else {
					defaultValue = nil
				}

				result.append(FunctionParameter(
					label: label,
					apiLabel: apiLabel,
					typeName: typeName,
					value: defaultValue,
					isVariadic: parameter.ellipsis != nil))
			}
			else {
				try result.append(FunctionParameter(
					label: "<<Error>>",
					apiLabel: nil,
					typeName: "<<Error>>",
					value: errorExpression(
						forASTNode: Syntax(parameter),
						withMessage: "Expected parameter to always have a first name and a type")))
			}
		}

		return result
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

			// If we can find the variable's name
			if let identifier = pattern.getText() {

				let expression: Expression?
				if let exprSyntax = patternBinding.initializer?.value {
					expression = try convertExpression(exprSyntax)
				}
				else {
					expression = nil
				}

				// If it's a `let _ = foo`
				guard identifier != "_" else {
					if let expression = expression {
						return [ExpressionStatement(
							range: variableDeclaration.getRange(inFile: self.sourceFile),
							expression: expression), ]
					}
					else {
						return []
					}
				}

				let annotatedType: String?
				if let typeAnnotation = patternBinding.typeAnnotation?.type {
					annotatedType = try convertType(typeAnnotation)
				}
				else  {
					annotatedType = expression?.swiftType
				}

				// Look for getters and setters
				var errorHappened = false
				var getter: FunctionDeclaration?
				var setter: FunctionDeclaration?
				if let maybeCodeBlock = patternBinding.children.first(where:
						{ $0.is(CodeBlockSyntax.self) }),
					let codeBlock = maybeCodeBlock.as(CodeBlockSyntax.self)
				{
					// TODO: test
					// If there's an implicit getter (e.g. `var a: Int { return 0 }`)
					let range = codeBlock.getRange(inFile: self.sourceFile)
					let statements = try convertBlock(codeBlock)

					guard let typeName = annotatedType else {
						let error = try errorStatement(
							forASTNode: Syntax(codeBlock),
							withMessage: "Expected variables with getters to have an explicit type")
						getter = FunctionDeclaration(
							range: range,
							prefix: "get",
							parameters: [], returnType: "", functionType: "", genericTypes: [],
							isOpen: false, isImplicit: false, isStatic: false, isMutating: false,
							isPure: false, isJustProtocolInterface: false, extendsType: nil,
							statements: [error],
							access: nil, annotations: [])
						errorHappened = true
						break
					}

					getter = FunctionDeclaration(
						range: codeBlock.getRange(inFile: self.sourceFile),
						prefix: "get",
						parameters: [],
						returnType: typeName,
						functionType: "() -> \(typeName)",
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
				else if let maybeAccesor = patternBinding.accessor,
					let accessorBlock = maybeAccesor.as(AccessorBlockSyntax.self)
				{
					// If there's an explicit getter or setter (e.g. `get { return 0 }`)

					for accessor in accessorBlock.accessors {
						let range = accessor.getRange(inFile: self.sourceFile)
						let prefix = accessor.accessorKind.text

						// If there the accessor has a body (if not, assume it's a protocol's
						// `{ get }`).
						if let maybeCodeBlock = accessor.children.first(where:
								{ $0.is(CodeBlockSyntax.self) }),
							let codeBlock = maybeCodeBlock.as(CodeBlockSyntax.self)
						{
							let statements = try convertBlock(codeBlock)

							guard let typeName = annotatedType else {
								let error = try errorStatement(
									forASTNode: Syntax(codeBlock),
									withMessage: "Expected variables with getters or setters to " +
										"have an explicit type")
								getter = FunctionDeclaration(
									range: range,
									prefix: prefix,
									parameters: [], returnType: "", functionType: "",
									genericTypes: [], isOpen: false, isImplicit: false,
									isStatic: false, isMutating: false, isPure: false,
									isJustProtocolInterface: false, extendsType: nil,
									statements: [error],
									access: nil, annotations: [])
								errorHappened = true
								break
							}

							let parameters: MutableList<FunctionParameter>
							if prefix == "get" {
								parameters = []
							}
							else {
								parameters = [FunctionParameter(
									label: "newValue",
									apiLabel: nil,
									typeName: typeName,
									value: nil)]
							}

							let returnType: String
							let functionType: String
							if prefix == "get" {
								returnType = typeName
								functionType = "() -> \(typeName)"
							}
							else {
								returnType = "()"
								functionType = "(\(typeName)) -> ()"
							}

							let functionDeclaration = FunctionDeclaration(
								range: range,
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

							if accessor.accessorKind.text == "get" {
								getter = functionDeclaration
							}
							else {
								setter = functionDeclaration
							}
						}
						else {
							let functionDeclaration = FunctionDeclaration(
								range: range,
								prefix: prefix,
								parameters: [],
								returnType: "",
								functionType: "",
								genericTypes: [],
								isOpen: false,
								isImplicit: false,
								isStatic: false,
								isMutating: false,
								isPure: false,
								isJustProtocolInterface: false,
								extendsType: nil,
								statements: [],
								access: nil,
								annotations: [])

							if accessor.accessorKind.text == "get" {
								getter = functionDeclaration
							}
							else {
								setter = functionDeclaration
							}
						}
					}
				}

				if errorHappened {
					continue
				}

				let accessAndAnnotations =
					getAccessAndAnnotations(fromModifiers: variableDeclaration.modifiers)

				let isStatic = accessAndAnnotations.annotations.remove("static")

				// Get annotations from `gryphon annotation` comments
				let annotationComments = getLeadingComments(
					forSyntax: Syntax(variableDeclaration),
					withKey: .annotation)
				let manualAnnotations = annotationComments.compactMap { $0.value }
				let annotations = accessAndAnnotations.annotations
				annotations.append(contentsOf: manualAnnotations)

				let isOpen: Bool
				if annotations.remove("final") {
					isOpen = false
				}
				else if let access = accessAndAnnotations.access, access == "open" {
					isOpen = true
				}
				else if isLet {
					// Only var's can be open in Swift
					isOpen = false
				}
				else {
					isOpen = !context.defaultsToFinal
				}

				result.append(VariableDeclaration(
					range: variableDeclaration.getRange(inFile: self.sourceFile),
					identifier: identifier,
					typeAnnotation: annotatedType,
					expression: expression,
					getter: getter,
					setter: setter,
					access: accessAndAnnotations.access,
					isOpen: isOpen,
					isLet: isLet,
					isImplicit: false,
					isStatic: isStatic,
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

	private func getAccessAndAnnotations(
		fromModifiers modifiers: ModifierListSyntax?)
		-> (access: String?, annotations: MutableList<String>)
	{
		if let modifiers = modifiers {
			let (accessSyntaxes, annonationSyntaxes) = List(modifiers).separate
				{ (syntax: DeclModifierSyntax) -> Bool in
					return syntax.name.text == "open" ||
						syntax.name.text == "public" ||
						syntax.name.text == "internal" ||
						syntax.name.text == "fileprivate" ||
						syntax.name.text == "private"
				}
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
		let leadingComments = getLeadingComments(forSyntax: Syntax(expression), withKey: .value)

		// If we're replacing this expression with a `gryphon value` comment
		let literalCodeExpressions = leadingComments.compactMap{ $0.value }
			.map {
				return LiteralCodeExpression(
					range: expression.getRange(inFile: self.sourceFile),
					string: $0,
					shouldGoToMainFunction: false,
					typeName: expression.getType(fromList: self.expressionTypes))
			}
		if let literalCodeExpression = literalCodeExpressions.first {
			return literalCodeExpression
		}

		if let tryExpression = expression.as(TryExprSyntax.self) {
			return try convertExpression(tryExpression.expression)
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
		if let optionalChainingExpression = expression.as(OptionalChainingExprSyntax.self) {
			return try convertOptionalChainingExpression(optionalChainingExpression)
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
			// Get the input parameter types (e.g. ["Any", "Any"] from
			// "(foo: (Any, Any) throws -> Any)")
			var closureType = typeName
			// Remove the enveloping parentheses
			// "(foo: (Any, Any) throws -> Any)" becomes "foo: (Any, Any) throws -> Any"
			while Utilities.isInEnvelopingParentheses(closureType) {
				closureType = String(closureType.dropFirst().dropLast())
			}

			// Separate the parameters (from the return type)
			// ...becomes "foo: (Any, Any) throws"
			let inputAndOutputTypes = Utilities.splitTypeList(closureType, separators: ["->"])
			var inputType = inputAndOutputTypes[0]

			// Remove the throws, if it's there
			// ...becomes "foo: (Any, Any)"
			if inputType.hasSuffix(" throws") {
				inputType = String(inputType.dropLast(" throws".count))
			}

			// Remove the label, if it's there
			// ...becomes "(Any, Any)"
			inputType = String(inputType.drop(while: { $0 != "(" }))

			// Remove the enveloping parentheses
			// ...becomes "Any, Any"
			while Utilities.isInEnvelopingParentheses(inputType) {
				inputType = String(inputType.dropFirst().dropLast())
			}

			// Separate the types
			// ...becomes ["Any", "Any"]
			let inputTypes = Utilities.splitTypeList(inputType, separators: [","])

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
			statements: try convertBlock(closureExpression),
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

				let typeName: String?
				if let operatorType =
						operatorSyntax.operatorToken.getType(fromList: self.expressionTypes),
					let resultType = Utilities.splitTypeList(operatorType, separators: ["->"]).last
				{
					// The operator type will be a function type like `(Int, Int) -> Int` for
					// `1 + 1`, so we use that function's result type
					typeName = resultType
				}
				else {
					typeName = nil
				}

				return BinaryOperatorExpression(
					range: range,
					leftExpression: leftHalf,
					rightExpression: rightHalf,
					operatorSymbol: operatorString,
					typeName: typeName)
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
	/// `MyType` `.` `member`, and the `MyType` can usually be obtained by searching for the type of
	///  the `.` token, which will be `MyType.Type`; when the type isn't available, it can be given
	/// by the `typeName` parameter.
	func convertMemberAccessExpression(
		_ memberAccessExpression: MemberAccessExprSyntax,
		typeName: String? = nil)
		throws -> Expression
	{
		// Get information for the right side
		guard let memberType = memberAccessExpression.getType(fromList: self.expressionTypes) ??
			typeName else
		{
			return try errorExpression(
				forASTNode: Syntax(memberAccessExpression),
				withMessage: "Failed to get a type for the member access expression")
		}

		let rightSideToken = memberAccessExpression.name
		let rightSideText = rightSideToken.text

		// Get information for the left side
		let leftExpression: Expression

		if let expressionSyntax = memberAccessExpression.base {
			// If it's an `expression` `.` `token`
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
		else if let leftType = typeName {
			// If it's an `.` `token` and the left type was given
			leftExpression = TypeExpression(
				range: memberAccessExpression.dot.getRange(inFile: self.sourceFile),
				typeName: leftType)
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
				range: rightSideToken.getRange(inFile: self.sourceFile),
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

	func convertOptionalChainingExpression(
		_ optionalChainingExpression: OptionalChainingExprSyntax)
		throws -> Expression
	{
		return OptionalExpression(
			range: optionalChainingExpression.getRange(inFile: self.sourceFile),
			expression: try convertExpression(optionalChainingExpression.expression))
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
		let string = floatLiteralExpression.floatingDigits.text
		// Remove the `_` from `1_000`
		let cleanString = string.replacingOccurrences(of: "_", with: "")

		if let typeName = floatLiteralExpression.getType(fromList: self.expressionTypes) {
			if typeName == "Float",
				let floatValue = Float(cleanString)
			{
				return LiteralFloatExpression(
					range: floatLiteralExpression.getRange(inFile: self.sourceFile),
					value: floatValue)
			}
			else if typeName == "Double",
				let doubleValue = Double(cleanString)
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
		let string = integerLiteralExpression.digits.text
		// Remove the `_` from `1_000`
		let cleanString = string.replacingOccurrences(of: "_", with: "")

		if let typeName = integerLiteralExpression.getType(fromList: self.expressionTypes) {
			if typeName == "Double",
				let doubleValue = Double(cleanString)
			{
				return LiteralDoubleExpression(
					range: integerLiteralExpression.getRange(inFile: self.sourceFile),
					value: doubleValue)
			}
			else if typeName.hasPrefix("Float"),
				let floatValue = Float(cleanString)
			{
				return LiteralFloatExpression(
					range: integerLiteralExpression.getRange(inFile: self.sourceFile),
					value: floatValue)
			}
			else if typeName.hasPrefix("UInt"),
				let uIntValue = UInt64(cleanString)
			{
				return LiteralUIntExpression(
					range: integerLiteralExpression.getRange(inFile: self.sourceFile),
					value: uIntValue)
			}
		}

		if let intValue = Int64(cleanString) {
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

			let isMultiline = (stringLiteralExpression.openQuote.tokenKind == .multilineStringQuote)

			var cleanText = text
			if isMultiline {
				// The text obtained from SwiftSyntax (as compared to whats considered semantically
				// in Swift) includes:
				// - an extra newline at the beggining
				// - an extra newline at the end, possibly followed by some indentation
				// The indentation before the end determines the indentation that will be ignored
				// throughout the string.

				// Ensure the string really does start and end with newlines
				if text.hasPrefix("\n"),
					let lastNewlineIndex = text.lastIndex(of: "\n"),
					text[text.index(after: lastNewlineIndex)...]
						.allSatisfy({ $0 == " " || $0 == "\t" })
				{
					let stringLines = text.split(
							withStringSeparator: "\n",
							omittingEmptySubsequences: false)
					let lastLine = stringLines.last!
					let indentation = lastLine

					let stringRange = stringLiteralExpression.getRange(inFile: self.sourceFile)

					let cleanLines = stringLines.dropFirst().dropLast().enumerated().map
						{ (index: Int, line: String) -> String in
							if line.isEmpty {
								// Empty lines are ok
								return line
							}

							if !line.hasPrefix(indentation) {
								// If we're dealing with different indentation, like spaces vs tabs
								let problemRange: SourceFileRange?
								if let range = stringRange {
									problemRange = SourceFileRange(
										lineStart: range.lineStart + index,
										lineEnd: range.lineStart + index,
										columnStart: 1,
										columnEnd: indentation.count + 1)
								}
								else {
									problemRange = nil
								}

								Compiler.handleWarning(
									message: "Unexpected indentation around here",
									ast: stringLiteralExpression.toPrintableTree(),
									sourceFile: self.sourceFile,
									sourceFileRange: problemRange)

								return line
							}
							else {
								return String(line.dropFirst(indentation.count))
							}
						}

					cleanText = cleanLines.joined(separator: "\n")
				}
				else {
					// This shouldn't happen
					Compiler.handleWarning(
						message: "Expected multiline strings to have extra newlines at the " +
						"beggining and at the end",
						ast: stringLiteralExpression.toPrintableTree(),
						sourceFile: self.sourceFile,
						sourceFileRange: stringLiteralExpression.getRange(inFile: self.sourceFile))
				}
			}

			return LiteralStringExpression(
				range: range,
				value: cleanText,
				isMultiline: isMultiline)
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
		if let attributedType = typeSyntax.as(AttributedTypeSyntax.self) {
			return try convertType(attributedType.baseType)
		}
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
		if let tupleType = typeSyntax.as(TupleTypeSyntax.self) {
			let elements = try tupleType.elements.map { try convertType($0.type) }
			return "(\(elements.joined(separator: ", ")))"
		}
		if let simpleType = typeSyntax.as(SimpleTypeIdentifierSyntax.self) {
			let baseType = simpleType.name.text
			if let generics = simpleType.genericArgumentClause?.arguments {
				let genericString = try generics
					.map { try convertType($0.argumentType) }
					.joined(separator: ", ")
				return baseType + "<" + genericString + ">"
			}

			return baseType
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

extension SyntaxProtocol {
	var asSyntax: Syntax {
		return Syntax(self)
	}
}

/// A protocol to convert FunctionDeclSyntax and InitializerDeclSyntax with the same algorithm.
protocol FunctionLikeSyntax: SyntaxProtocol {
	var isInitializer: Bool { get }
	var prefix: String { get }
	var parameterList: FunctionParameterListSyntax { get }
	var statements: CodeBlockSyntax? { get }
	var modifierList: ModifierListSyntax? { get }
	var returnType: TypeSyntax? { get }
	var generics: GenericParameterListSyntax? { get }
	/// For optional initializers
	var isOptional: Bool { get }
}

extension FunctionDeclSyntax: FunctionLikeSyntax {
	var isInitializer: Bool {
		return false
	}

	var prefix: String {
		return self.identifier.text
	}

	var parameterList: FunctionParameterListSyntax {
		return self.signature.input.parameterList
	}

	var statements: CodeBlockSyntax? {
		return self.body
	}

	var modifierList: ModifierListSyntax? {
		return self.modifiers
	}

	var returnType: TypeSyntax? {
		return signature.output?.returnType
	}

	var generics: GenericParameterListSyntax? {
		return self.genericParameterClause?.genericParameterList
	}

	var isOptional: Bool {
		return false
	}
}

extension InitializerDeclSyntax: FunctionLikeSyntax {
	var isInitializer: Bool {
		return true
	}

	var prefix: String {
		return "init"
	}

	var parameterList: FunctionParameterListSyntax {
		return self.parameters.parameterList
	}

	var statements: CodeBlockSyntax? {
		return self.body
	}

	var modifierList: ModifierListSyntax? {
		return self.modifiers
	}

	var returnType: TypeSyntax? {
		// FIXME: InitializerDeclSyntaxes don't seem to have access to the returnType. This might
		// cause problems. Maybe we can set the type in a TranspilationPass, based on the enveloping
		// class.
		return nil
	}

	var generics: GenericParameterListSyntax? {
		return self.genericParameterClause?.genericParameterList
	}

	var isOptional: Bool {
		return (self.optionalMark != nil)
	}
}

/// A protocol to convert IfStmtSyntax and GuardStmtSyntax with the same algorithm.
protocol IfLikeSyntax: SyntaxProtocol {
	var ifConditions: ConditionElementListSyntax { get }
	var statements: CodeBlockSyntax { get }
	var elseBlock: CodeBlockSyntax? { get }
	var isGuard: Bool { get }
}

extension IfStmtSyntax: IfLikeSyntax {
	var ifConditions: ConditionElementListSyntax {
		return self.conditions
	}

	var statements: CodeBlockSyntax {
		return self.body
	}

	var elseBlock: CodeBlockSyntax? {
		return self.elseBody?.as(CodeBlockSyntax.self)
	}

	var isGuard: Bool {
		return false
	}
}

extension GuardStmtSyntax: IfLikeSyntax {
	var ifConditions: ConditionElementListSyntax {
		return self.conditions
	}

	var statements: CodeBlockSyntax {
		return self.body
	}

	var elseBlock: CodeBlockSyntax? {
		return nil
	}

	var isGuard: Bool {
		return true
	}
}

/// A syntax that represents a code block. Contains a SyntaxList of statements and an endSyntax
/// (usually a closing brace) from which to get the final comments (using its `leadingSyntax` and
/// `position.utf8offset`).
protocol SyntaxListContainer {
	associatedtype ElementList: SyntaxList
	var syntaxElements: ElementList { get }
	var endSyntax: Syntax { get }
}

extension CodeBlockSyntax: SyntaxListContainer {
	var syntaxElements: CodeBlockItemListSyntax {
		return self.statements
	}
	var endSyntax: Syntax {
		return Syntax(self.rightBrace)
	}
}

extension MemberDeclBlockSyntax: SyntaxListContainer {
	var syntaxElements: MemberDeclListSyntax {
		return self.members
	}
	var endSyntax: Syntax {
		return Syntax(self.rightBrace)
	}
}

extension ClosureExprSyntax: SyntaxListContainer {
	var syntaxElements: CodeBlockItemListSyntax {
		return self.statements
	}
	var endSyntax: Syntax {
		return Syntax(self.rightBrace)
	}
}

extension SourceFileSyntax: SyntaxListContainer {
	var syntaxElements: CodeBlockItemListSyntax {
		return self.statements
	}
	var endSyntax: Syntax {
		return Syntax(self.eofToken)
	}
}

struct SomeSyntaxListContainer: SyntaxListContainer {
	let syntaxElements: CodeBlockItemListSyntax
	let endSyntax: Syntax
}

/// A sytax that represents a list of elements, e.g. a list of statements or declarations.
protocol SyntaxList: Sequence where Element: SyntaxElementContainer { }

/// An element wrapper in a list of syntaxes (e.g. a list of declarations or statements).
/// These lists, like `MemberDeclListSyntax` and `CodeBlockItemListSyntax`, usually wrap their
/// elements in these containers. This protocol allows us to use them generically.
protocol SyntaxElementContainer: SyntaxProtocol {
	var element: Syntax { get }
}

extension List: SyntaxList where Element: SyntaxElementContainer { }

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


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

/// Seems to return true if there needs to be a fix, and false if everything went OK.
///
/// Note: taken from the Swift compiler in 2020-08-20 at
/// https://github.com/apple/swift/tree/3ad8ea86bbca9c430da9f664a6222ebd2ca65a56/lib/Sema/
/// 	CSSimplify.cpp#L252
///
/// \param args The arguments of the call
/// \param params The parameters of the function definition
/// \param paramInfo Information on the (definition's?) default arguments and whether they accept
/// 	unlabeled trailing closures.
/// \param trailingClosureMatching If we're trying to match the trailing closures forwards or
/// 	backwards
///
/// The result of the match is stored in the given `parameterBindings` array, which this method
/// empties and then populates. Each element of the array corresponds to a parameter in the function
/// declaration, and contains the indices of the call's arguments that correspond to that parameter.
/// Common parameters will contain the index of a single corresponding argument, but they may also
/// contain multiple indices (if the parameter is variadic) or no indices (if we're using the
/// default value). For example: `[[0], [1, 2], []]`.
///
/// Some code isn't included from original algorithm, like code that needed types or code that deals
/// with trailing closures. Some parts of that code are still here, though, to make it easier to
/// include later if needed.
func matchCallArguments(
	args: List<LabeledExpression>,
	params: List<FunctionParameter>,
	paramInfo: ParameterListInfo,
	unlabeledTrailingClosureArgIndex: Int?,
	trailingClosureMatching: TrailingClosureMatching,
	parameterBindings: MutableList<MutableList<Int>>)
	-> Bool
{
	assert(params.count == paramInfo.defaultArguments.count,
			// && params.count == paramInfo.acceptsUnlabeledTrailingClosures.count,
		"Default map does not match")
	assert(unlabeledTrailingClosureArgIndex == nil ||
		unlabeledTrailingClosureArgIndex! < args.count)

	// Keep track of the parameter we're matching and what argument indices
	// got bound to each parameter.
	let numParams = params.count
	parameterBindings.removeAll()
	for _ in 0..<numParams {
		parameterBindings.append([])
	}

	// Keep track of which arguments we have claimed from the argument tuple.
	let numArgs = args.count
	let claimedArgs = MutableList<Bool>(repeating: false, count: numArgs)
	let actualArgNames: MutableList<String?> = []
	var numClaimedArgs = 0

	// Local function that claims the argument at \c argNumber, returning the
	// index of the claimed argument. This is primarily a helper for
	// \c claimNextNamed.
	let claim =
	{ (expectedName: String?, argNumber: Int, ignoreNameClash: Bool /* = false */) -> Int in
		// Make sure we can claim this argument.
		assert(argNumber != numArgs, "Must have a valid index to claim")
		assert(!claimedArgs[argNumber], "Argument already claimed")

		if !actualArgNames.isEmpty {
			// We're recording argument names; record this one.
			actualArgNames[argNumber] = expectedName
		}
		else if args[argNumber].label != expectedName, !ignoreNameClash {
			// We have an argument name mismatch. Start recording argument names.
			// Figure out previous argument names from the parameter bindings.
			for i in params.indices {
				let param = params[i]
				var firstArg = true

				for argIdx in parameterBindings[i] {
					actualArgNames[argIdx] = firstArg ? param.apiLabel : ""
					firstArg = false
				}
			}

			// Record this argument name.
			actualArgNames[argNumber] = expectedName
		}

		claimedArgs[argNumber] = true
		numClaimedArgs += 1
		return argNumber;
	}

	// Local function that skips over any claimed arguments.
	let skipClaimedArgs = { (nextArgIdx: inout Int) -> Int in
		while nextArgIdx != numArgs, claimedArgs[nextArgIdx] {
			nextArgIdx += 1
		}
		return nextArgIdx
	}

	// Local function that retrieves the next unclaimed argument with the given
	// name (which may be empty). This routine claims the argument.
	let claimNextNamed =
	{ (nextArgIdx: inout Int,
	   paramLabel: String?,
	   ignoreNameMismatch: Bool,
	   forVariadic: Bool /* = false */) -> Int? in
		// Skip over any claimed arguments.
		_ = skipClaimedArgs(&nextArgIdx)

		// If we've claimed all of the arguments, there's nothing more to do.
		if numClaimedArgs == numArgs {
			return nil
		}

		// Go hunting for an unclaimed argument whose name does match.
		var claimedWithSameName: Int?

		var i: Int = nextArgIdx
		while i != numArgs {
			let argLabel = args[i].label

			if argLabel != paramLabel {
				// If this is an attempt to claim additional unlabeled arguments
				// for variadic parameter, we have to stop at first labeled argument.
				if forVariadic {
					return nil
				}

				// Otherwise we can continue trying to find argument which
				// matches parameter with or without label.
				i += 1
				continue
			}

			// Skip claimed arguments.
			if claimedArgs[i] {
				assert(!forVariadic, "Cannot be for a variadic claim")
				// Note that we have already claimed an argument with the same name.
				if claimedWithSameName == nil {
					claimedWithSameName = i
				}

				i += 1
				continue
			}

			// We found a match.  If the match wasn't the next one, we have
			// potentially out of order arguments.
			if i != nextArgIdx {
				assert(!forVariadic, "Cannot be for a variadic claim")
				// Avoid claiming un-labeled defaulted parameters
				// by out-of-order un-labeled arguments or parts
				// of variadic argument sequence, because that might
				// be incorrect:
				// ```swift
				// func foo(_ a: Int, _ b: Int = 0, c: Int = 0, _ d: Int) {}
				// foo(1, c: 2, 3) // -> `3` will be claimed as '_ b:'.
				// ```
				if argLabel == nil || argLabel!.isEmpty {
					i += 1
					continue
				}
			}

			// Claim it.
			return claim(paramLabel, i, false)
		}

		// If we're not supposed to attempt any fixes, we're done.
		return nil
	}

	// Local function that attempts to bind the given parameter to arguments in
	// the list.
	let bindNextParameter =
	{ (paramIdx: Int, nextArgIdx: inout Int, ignoreNameMismatch: Bool) in
		let param = params[paramIdx]
		var paramLabel = param.apiLabel

		// If we have the trailing closure argument and are performing a forward
		// match, look for the matching parameter.
		if (trailingClosureMatching == .forward &&
			unlabeledTrailingClosureArgIndex != nil &&
			skipClaimedArgs(&nextArgIdx) == unlabeledTrailingClosureArgIndex)
		{
			// If the parameter we are looking at does not support the (unlabeled)
			// trailing closure argument, this parameter is unfulfilled.
			if (!paramInfo.acceptsUnlabeledTrailingClosures[paramIdx] &&
				!ignoreNameMismatch)
			{
				return
			}

			// If this parameter does not require an argument, consider applying a
			// "fuzzy" match rule that skips this parameter if doing so is the only
			// way to successfully match arguments to parameters.
			if !parameterRequiresArgument(params: params, paramInfo: paramInfo, paramIdx: paramIdx),
				anyParameterRequiresArgument(
					params: params,
					paramInfo: paramInfo,
					firstParamIdx: paramIdx + 1,
					beforeLabel: nextArgIdx + 1 < numArgs
						? args[nextArgIdx + 1].label
						: nil)
			{
				return
			}

			// The argument is unlabeled, so mark the parameter as unlabeled as
			// well.
			paramLabel = nil
		}


		// Handle variadic parameters.
		if param.isVariadic {

			// Claim the next argument with the name of this parameter.
			let maybeClaimed = claimNextNamed(&nextArgIdx, paramLabel, ignoreNameMismatch, false)

			// If there was no such argument, leave the parameter unfulfilled.
			guard let claimed = maybeClaimed else {
				return
			}

			// Record the first argument for the variadic.
			parameterBindings[paramIdx].append(claimed)

			let currentNextArgIdx = nextArgIdx

			nextArgIdx = claimed

			// Claim any additional unnamed arguments.
			while true {
				// If the next argument is the unlabeled trailing closure and the
				// variadic parameter does not accept the unlabeled trailing closure
				// argument, we're done.
				if trailingClosureMatching == .forward,
					let unlabeledTrailingClosureArgIndex = unlabeledTrailingClosureArgIndex,
					skipClaimedArgs(&nextArgIdx) == unlabeledTrailingClosureArgIndex,
					!paramInfo.acceptsUnlabeledTrailingClosures[paramIdx]
				{
					break
				}

				if let claimed = claimNextNamed(&nextArgIdx, nil, false, true) {
					parameterBindings[paramIdx].append(claimed)
				}
				else {
					break
				}
			}

			nextArgIdx = currentNextArgIdx
			return
		}

		// Try to claim an argument for this parameter.
		if let claimed = claimNextNamed(&nextArgIdx, paramLabel, ignoreNameMismatch, false) {
			parameterBindings[paramIdx].append(claimed)
			return
		}
	}

	// If we have an unlabeled trailing closure and are matching backward, match
	// the trailing closure argument near the end.
	if let unlabeledTrailingClosureArgIndex = unlabeledTrailingClosureArgIndex,
		trailingClosureMatching == .backward
	{
		assert(!claimedArgs[unlabeledTrailingClosureArgIndex])

		// One past the next parameter index to look at.
		let prevParamIdx = numParams

		// Scan backwards from the end to match the unlabeled trailing closure.
		// Optional<unsigned> unlabeledParamIdx;
		var unlabeledParamIdx: Int? = nil

		if prevParamIdx > 0 {
			var paramIdx = prevParamIdx - 1

			var lastAcceptsTrailingClosure = false

			// If the last parameter is defaulted, this might be
			// an attempt to use a trailing closure with previous
			// parameter that accepts a function type e.g.
			//
			// func foo(_: () -> Int, _ x: Int = 0) {}
			// foo { 42 }
			if paramIdx > 0 &&
				paramInfo.defaultArguments[paramIdx]
			{
				let paramType = params[paramIdx - 1].typeName
				// If the parameter before defaulted last accepts.
				if paramType.contains("->") {
					lastAcceptsTrailingClosure = true
					paramIdx -= 1
				}
			}

			if (lastAcceptsTrailingClosure) {
				unlabeledParamIdx = paramIdx
			}
		}

		// Trailing closure argument couldn't be matched to anything. Fail fast.
		guard let nonNilUnlabeledParamIdx = unlabeledParamIdx else {
			return true
		}

		// Claim the parameter/argument pair.
		_ = claim(params[nonNilUnlabeledParamIdx].apiLabel,
			unlabeledTrailingClosureArgIndex,
			/*ignoreNameClash=*/true)
		parameterBindings[nonNilUnlabeledParamIdx].append(
			unlabeledTrailingClosureArgIndex)
	}

	var nextArgIdx = 0
	// Mark through the parameters, binding them to their arguments.
	for paramIdx in params.indices {
		if (parameterBindings[paramIdx].isEmpty) {
			bindNextParameter(paramIdx, &nextArgIdx, false)
		}
	}

	// If we have any unclaimed arguments, the matching failed.
	if numClaimedArgs != numArgs {
		return true
	}

	// If no arguments were renamed, the call arguments match up with the
	// parameters.
	if actualArgNames.isEmpty {
		return false
	}
	else {
		return true
	}
}

/// Determine whether any parameter from the given index up until the end
/// requires an argument to be provided.
///
/// \param params The parameters themselves.
/// \param paramInfo Declaration-provided information about the parameters.
/// \param firstParamIdx The first parameter to examine to determine whether any
/// parameter in the range \c [paramIdx, params.size()) requires an argument.
/// \param beforeLabel If non-empty, stop examining parameters when we reach
/// a parameter with this label.
func anyParameterRequiresArgument(
	params: List<FunctionParameter>,
	paramInfo: ParameterListInfo,
	firstParamIdx: Int,
	beforeLabel: String?) -> Bool
{
	for paramIdx in firstParamIdx..<params.count {
		// If have been asked to stop when we reach a parameter with a particular
		// label, and we see a parameter with that label, we're done: no parameter
		// requires an argument.
		if let beforeLabel = beforeLabel, beforeLabel == params[paramIdx].apiLabel {
			break
		}

		// If this parameter requires an argument, tell the caller.
		if parameterRequiresArgument(params: params, paramInfo: paramInfo, paramIdx: paramIdx) {
			return true
		}
	}

	// No parameters required arguments.
	return false
}

/// Whether the given parameter requires an argument.
func parameterRequiresArgument(
	params: List<FunctionParameter>,
	paramInfo: ParameterListInfo,
	paramIdx: Int) -> Bool
{
	return !paramInfo.defaultArguments[paramIdx]
		&& !params[paramIdx].isVariadic
}

enum TrailingClosureMatching {
	case forward
	case backward
}

struct ParameterListInfo {
	let defaultArguments: List<Bool>
	let acceptsUnlabeledTrailingClosures: List<Bool> = []
}

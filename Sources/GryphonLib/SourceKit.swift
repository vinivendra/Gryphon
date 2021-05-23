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

import Foundation
import SwiftSyntax
import SourceKittenFramework

public class SourceKit {
	struct ExpressionType {
		let offset: Int
		let length: Int
		let typeName: SwiftType
	}

	/// Executes an indexing request using SourceKit. Returns the raw result of the request.
	static func requestIndexing(
		forFileAtPath filePath: String,
		context: TranspilationContext)
	throws -> Map<String, SourceKitRepresentable>
	{
		Compiler.logStart("🧑‍💻  Calling SourceKit (indexing)...")
		let logInfo = Log.startLog(name: "SourceKit Indexing")

		defer {
			// End the log for Instruments even if errors are thrown
			Log.endLog(info: logInfo)
		}

		let absolutePath = Utilities.getAbsolutePath(forFile: filePath)
		let arguments = try context.getArgumentsForSourceKit().array

		Compiler.log("ℹ️  Request for file \"\(absolutePath)\"")
		Compiler.log("ℹ️  Request with compiler arguments: [")
		for argument in arguments {
			Compiler.log("\t\"\(argument)\",")
		}
		Compiler.log("]")

		let request = Request.index(file: absolutePath, arguments: arguments)
		let sourceKitResult: [String: SourceKitRepresentable] = try request.send()

		processTypeUSRs(forIndexingResponse: sourceKitResult)

		Compiler.logEnd("✅  Done calling SourceKit (indexing).")

		return Map(sourceKitResult)
	}

	/// Maps a type's USR to the type's name
	static let typeUSRs: Atomic<MutableMap<String, String>> = Atomic([:])

	/// Goes through the `indexingResponse` recording the USR for any type it finds. Expects the
	/// `indexingResponse` to be a valid tree from a SourceKit indexing request, but it can be
	/// either the root of the tree or an inner node.
	private static func processTypeUSRs(
		forIndexingResponse indexingResponse: [String: SourceKitRepresentable])
	{
		guard let children =
				indexingResponse["key.entities"] as? [[String: SourceKitRepresentable]] else
		{
			return
		}

		// The `kind` strings can be found at
		// https://github.com/apple/swift/blob/main/utils/gyb_sourcekit_support/UIDs.py
		for child in children {
			if let kind = child["key.kind"] as? String,
			   kind == "source.lang.swift.ref.struct" ||
				kind == "source.lang.swift.ref.class" ||
				kind == "source.lang.swift.ref.enum" ||
				kind == "source.lang.swift.decl.struct" ||
				kind == "source.lang.swift.decl.class" ||
				kind == "source.lang.swift.decl.enum",
			   let name = child["key.name"] as? String,
			   let usr = child["key.usr"] as? String
			{
				if !usr.hasPrefix("s:") {
					Compiler.handleWarning(
						message: "Unexpected USR (\"\(usr)\") for type (\"\(name)\")",
						syntax: nil, sourceFile: nil, sourceFileRange: nil)
				}
				else {
					let cleanUSR = String(usr.dropFirst("s:".count))
					typeUSRs.mutateAtomically { $0[cleanUSR] = name }
				}
			}

			processTypeUSRs(forIndexingResponse: child)
		}
	}

	/// Looks in the `indexingResponse` for the given `expression`.
	/// Expects the `indexingResponse` to be a valid tree from a SourceKit
	/// indexing request, but it can be either the root of the tree or an inner node.
	static func searchForExpression(
		inRange range: SourceFileRange?,
		withIdentifier identifier: String,
		inIndexingResponse indexingResponse: [String: SourceKitRepresentable])
	-> [String: SourceKitRepresentable]?
	{
		guard let expressionRange = range,
			  let children =
				indexingResponse["key.entities"] as? [[String: SourceKitRepresentable]] else
		{
			return nil
		}

		// We only have access to the start position of each entity's range, so if an entity is
		// enveloping our expression, it will have a start position before our expression.
		for index in children.indices {
			let child = children[index]

			if let columnInt64 = child["key.column"] as? Int64,
			   let lineInt64 = child["key.line"] as? Int64
			{
				let column = Int(columnInt64)
				let line = Int(lineInt64)
				let childPosition = SourceFilePosition(line: line, column: column)
				if childPosition < expressionRange.start {
					// It might be inside this child
					if let result = searchForExpression(
						inRange: range,
						withIdentifier: identifier,
						inIndexingResponse: child)
					{
						return result
					}
					else {
						continue
					}
				}
				else if childPosition == expressionRange.start {
					// It might be this one

					if let kind = child["key.kind"] as? String,
					   (kind == "source.lang.swift.ref.var.instance" ||
							kind == "source.lang.swift.ref.function.method.instance" ||
							kind == "source.lang.swift.ref.var.static" ||
							kind == "source.lang.swift.ref.function.method.static"),
					   let name = child["key.name"] as? String,
					   (name == identifier || name.hasPrefix(identifier + "("))
					{
						// This is the one
						return child
					}
					else {
						// Right range but wrong contents; look inside it
						return searchForExpression(
							inRange: expressionRange,
							withIdentifier: identifier,
							inIndexingResponse: child)
					}
				}
				else {
					// This one is after the one we're looking for
					continue
				}
			}
		}

		// If the last child was still before the searched expression, look inside it.
		if let lastChild = children.last {
			return searchForExpression(
				inRange: expressionRange,
				withIdentifier: identifier,
				inIndexingResponse: lastChild)
		}
		else {
			return nil
		}
	}

	/// Calls `search(forExpression:, inIndexingResponse:)`
	/// to look for the given expression. If the expression is found,
	/// looks into the expression's `usr` to try to identify if it is declared
	/// in the Swift standard library.
	/// If the expression is not found, returns `false`.
	static func expressionIsFromTheSwiftStandardLibrary(
		expressionRange: SourceFileRange?,
		expressionIdentifier: String,
		usingIndexingResponse indexingResponse: [String: SourceKitRepresentable])
	-> Bool
	{
		if let child = searchForExpression(
			inRange: expressionRange,
			withIdentifier: expressionIdentifier,
			inIndexingResponse: indexingResponse),
		   let usr = child["key.usr"] as? String
		{
			return usr.hasPrefix("s:s")
		}
		else {
			return false
		}
	}

	/// Calls `search(forExpression:, inIndexingResponse:)`
	/// to look for the given expression. If the expression is found,
	/// looks into the expression's `usr` to try to identify its parent type (e.g. `String` for
	/// `String.startIndex`).
	static func getParentType(
		forExpression expression: DeclarationReferenceExpression,
		usingIndexingResponse indexingResponse: Map<String, SourceKitRepresentable>)
	-> String?
	{
		guard let child = searchForExpression(
				inRange: expression.range,
				withIdentifier: expression.identifier,
				inIndexingResponse: indexingResponse.dictionary) else
		{
			return nil
		}

		// Checks for a property
		if let kind = child["key.kind"] as? String,
		   kind == "source.lang.swift.ref.var.instance",
		   let name = child["key.name"] as? String,
		   name == expression.identifier,
		   let grandchildren =
			child["key.entities"] as? [[String: SourceKitRepresentable]],
		   let getterGrandchild = grandchildren.first(where:
														{ $0["key.kind"] as? String == "source.lang.swift.ref.function.accessor.getter" }),
		   let parentUSR = getterGrandchild["key.receiver_usr"] as? String // `s:SS`
		{
			// Remove the starting `s:`
			let cleanParentUSR = String(parentUSR
											.drop(while: { !$0.isPunctuation })
											.dropFirst())
			return typeUSRs.atomic[cleanParentUSR]
		}
		// Checks for a method
		else if let kind = child["key.kind"] as? String,
				kind == "source.lang.swift.ref.function.method.instance",
				let name = child["key.name"] as? String, // something like `foo(bar:)`
				name.hasPrefix(expression.identifier + "("),
				let parentUSR = child["key.receiver_usr"] as? String // `s:SS`
		{
			// Remove the starting `s:`
			let cleanParentUSR = String(parentUSR
											.drop(while: { !$0.isPunctuation })
											.dropFirst())
			return typeUSRs.atomic[cleanParentUSR]
		}
		else {
			return nil
		}
	}

	/// Executes an indexing request using SourceKit. Returns the result of the request, processed
	/// into a list of `ExpressionTypes`.
	static func requestExpressionTypes(
		forFile sourceFile: SourceFile,
		context: TranspilationContext)
	throws -> SortedList<ExpressionType>
	{
		Compiler.logStart("🧑‍💻  Calling SourceKit (expression types)...")
		let logInfo = Log.startLog(name: "SourceKit Expression Types")

		defer {
			// End the log for Instruments even if errors are thrown
			Log.endLog(info: logInfo)
		}

		// Call SourceKitten to get the types
		let absolutePath = Utilities.getAbsolutePath(forFile: sourceFile.path)
		let compilationArgumentsString = try context.getArgumentsForSourceKit()
			.map { "\"\($0)\"" }
			.joined(separator: ",\n    ")
		let yaml = """
		{
		  key.request: source.request.expression.type,
		  key.compilerargs: [
			\(compilationArgumentsString)
		  ],
		  key.sourcefile: "\(absolutePath)"
		}
		"""

		Compiler.log("Request with YAML:\n\"\"\"\(yaml)\"\"\"")

		let sourceKitResult: [String: SourceKitRepresentable]
		do {
			let request = Request.yamlRequest(yaml: yaml)
			sourceKitResult = try request.send()
		}
		catch let error {
			throw GryphonError(errorMessage: "Failed to call SourceKit: " +
								"\(error.localizedDescription)")
		}

		let list = sourceKitResult["key.expression_type_list"]
			as! [[String: SourceKitRepresentable]]

		let astsAndTypes: [(ast: [String: SourceKitRepresentable],
							type: SourceKit.ExpressionType)] =
			try list.map { ast in
				let typeName = ast["key.expression_type"]! as! String
				let syntax = try! SwiftSyntax.SyntaxParser.parse(source: "let x: \(typeName)")
				let typeSyntax = syntax.statements.first!
					.item.as(VariableDeclSyntax.self)!
					.bindings.first!
					.typeAnnotation!
					.type
				let swiftType = try typeSyntax.toSwiftType(usingSourceFile: sourceFile)

				return (ast,
						ExpressionType(
							offset: Int(ast["key.expression_offset"]! as! Int64),
							length: Int(ast["key.expression_length"]! as! Int64),
							typeName: swiftType))
			}

		// If there's an error, we might have to re-init to include a new file in the compilation.
		// Throw an error here so that the caller has the opportunity to do that.
		if let errorASTAndType =
			astsAndTypes.first(where: { $0.type.typeName.description == "<<error type>>" })
		{
			var errorMessage = "SourceKit failed to get an expression's type"
			if context.xcodeProjectPath != nil {
				errorMessage += ". Try running `gryphon init` again."
			}

			let range = sourceFile.getRange(
				forSourceKitOffset: errorASTAndType.type.offset,
				length: errorASTAndType.type.length)

			let completeMessage = CompilerIssue(
				message: errorMessage,
				ast: errorASTAndType.ast.toPrintableTree(),
				sourceFile: sourceFile,
				sourceFileRange: range,
				isError: true)
				.fullMessage

			throw GryphonError(errorMessage: completeMessage)
		}

		// Sort by offset (ascending), breaking ties using length (ascending)
		let types = astsAndTypes.map { $0.type }
		let sortedTypes = SortedList(types) { a, b in
			if a.offset == b.offset {
				return a.length < b.length
			}
			else {
				return a.offset < b.offset
			}
		}

		Compiler.logEnd("✅  Done calling SourceKit (expression types).")

		return sortedTypes
	}
}

extension SourceKitRepresentable {
	func toPrintableTree() -> PrintableTree {
		if let array = self as? [SourceKitRepresentable] {
			let subtrees: List<PrintableAsTree?> = List(array.map { $0.toPrintableTree() })
			return PrintableTree("Array", subtrees)
		}
		else if let dictionary = self as? [String: SourceKitRepresentable] {
			let subtrees: List<PrintableAsTree?> =
				List(dictionary.map { PrintableTree($0, [$1.toPrintableTree()]) })
			return PrintableTree("Object", subtrees)
		}
		else {
			return PrintableTree(String(describing: self))
		}
	}
}

extension SyntaxProtocol {
	func getType(fromList list: SortedList<SourceKit.ExpressionType>) -> String? {
		let offset = self.positionAfterSkippingLeadingTrivia.utf8Offset
		let length = self.contentLength.utf8Length

		let result = list.search { typeExpression in
			// Types are sorted by offset
			if typeExpression.offset < offset {
				return .orderedAscending
			}
			else if typeExpression.offset > offset {
				return .orderedDescending
			}
			else { // Offset ties are sorted by length
				if typeExpression.length < length {
					return .orderedAscending
				}
				else if typeExpression.length > length {
					return .orderedDescending
				}
				else {
					return .orderedSame
				}
			}
		}

		return result?.typeName.description
	}
}

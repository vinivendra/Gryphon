/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation

public class GRYLibraryTranspilationPass: GRYTranspilationPass {
	struct Template {
		let expression: GRYExpression
		let string: String
	}

	static var templates = [Template]()

	static func loadTemplates() {
		try! GRYUtils.updateLibraryFiles()

		let libraryFilesPath: String = Process().currentDirectoryPath + "/Library Templates/"
		let currentURL = URL(fileURLWithPath: libraryFilesPath)
		let fileURLs = try! FileManager.default.contentsOfDirectory(
			at: currentURL,
			includingPropertiesForKeys: nil)
		let templateFiles = fileURLs.filter {
				$0.pathExtension == GRYFileExtension.gryRawAstJson.rawValue
		}.sorted { (url1: URL, url2: URL) -> Bool in
					url1.absoluteString < url2.absoluteString
		}

		var previousExpression: GRYExpression?
		for file in templateFiles {
			let filePath = file.path
			let ast = GRYAst.initialize(fromJsonInFile: filePath)
			let expressions = ast.statements.compactMap
			{ (node: GRYTopLevelNode) -> GRYExpression? in
				if case let .expression(expression: expression) = node {
					return expression
				}
				else {
					return nil
				}
			}

			for expression in expressions {
				if let templateExpression = previousExpression {
					guard case let .literalStringExpression(value: value) = expression else {
						continue
					}
					templates.append(Template(expression: templateExpression, string: value))
					previousExpression = nil
				}
				else {
					previousExpression = expression
				}
			}
		}
	}

	override func run(on sourceFile: GRYAst) -> GRYAst {
		if GRYLibraryTranspilationPass.templates.isEmpty {
			GRYLibraryTranspilationPass.loadTemplates()
		}
		return super.run(on: sourceFile)
	}

	override func replaceExpression(_ expression: GRYExpression) -> GRYExpression {
		for template in GRYLibraryTranspilationPass.templates {
			if let matches = expression.matches(template.expression) {
				return .templateExpression(pattern: template.string, matches: matches)
			}
		}
		return super.replaceExpression(expression)
	}
}

extension GRYExpression {
	func matches(_ template: GRYExpression) -> [String: GRYExpression]? {
		var result = [String: GRYExpression]()
		let success = matches(template, &result)
		if success {
			return result
		}
		else {
			return nil
		}
	}

	private func matches(
		_ template: GRYExpression, _ matches: inout [String: GRYExpression]) -> Bool
	{
		if case let .declarationReferenceExpression(
			identifier: identifier, type: templateType) = template,
			identifier.hasPrefix("_"),
			self.type == templateType
		{
			matches[identifier] = self
			return true
		}
		else {
			switch (self, template) {
			case let (
				.literalCodeExpression(string: leftString),
				.literalCodeExpression(string: rightString)):

				return leftString == rightString
			case let (
				.parenthesesExpression(expression: leftExpression),
				.parenthesesExpression(expression: rightExpression)):

				return leftExpression.matches(rightExpression, &matches)
			case let (
				.forceValueExpression(expression: leftExpression),
				.forceValueExpression(expression: rightExpression)):

				return leftExpression.matches(rightExpression, &matches)
			case let
				(.declarationReferenceExpression(identifier: leftIdentifier, type: leftType),
				 .declarationReferenceExpression(identifier: rightIdentifier, type: rightType)):

				return leftIdentifier == rightIdentifier && leftType == rightType
			case let
				(.typeExpression(type: leftType),
				 .typeExpression(type: rightType)):

				return leftType == rightType
			case let
				(.subscriptExpression(
					subscriptedExpression: leftSubscriptedExpression,
					indexExpression: leftIndexExpression, type: leftType),
				 .subscriptExpression(
					subscriptedExpression: rightSubscriptedExpression,
					indexExpression: rightIndexExpression, type: rightType)):

					return leftSubscriptedExpression.matches(rightSubscriptedExpression, &matches)
						&& leftIndexExpression.matches(rightIndexExpression, &matches)
						&& leftType == rightType
			case let
				(.arrayExpression(elements: leftElements, type: leftType),
				 .arrayExpression(elements: rightElements, type: rightType)):

				var result = true
				for (leftElement, rightElement) in zip(leftElements, rightElements) {
					result = result && leftElement.matches(rightElement, &matches)
				}
				return result && (leftType == rightType)
			case let
				(.dotExpression(
					leftExpression: leftLeftExpression, rightExpression: leftRightExpression),
				 .dotExpression(
					leftExpression: rightLeftExpression, rightExpression: rightRightExpression)):

				return leftLeftExpression.matches(rightLeftExpression, &matches) &&
					leftRightExpression.matches(rightRightExpression, &matches)
			case let
				(.binaryOperatorExpression(
					leftExpression: leftLeftExpression, rightExpression: leftRightExpression,
					operatorSymbol: leftOperatorSymbol, type: leftType),
				 .binaryOperatorExpression(
					leftExpression: rightLeftExpression, rightExpression: rightRightExpression,
					operatorSymbol: rightOperatorSymbol, type: rightType)):

				return leftLeftExpression.matches(rightLeftExpression, &matches) &&
					leftRightExpression.matches(rightRightExpression, &matches) &&
					(leftOperatorSymbol == rightOperatorSymbol) && (leftType == rightType)
			case let
				(.unaryOperatorExpression(
					expression: leftExpression, operatorSymbol: leftOperatorSymbol, type: leftType),
				 .unaryOperatorExpression(
					expression: rightExpression, operatorSymbol: rightOperatorSymbol,
					type: rightType)):

				return leftExpression.matches(rightExpression, &matches) &&
					(leftOperatorSymbol == rightOperatorSymbol) && (leftType == rightType)
			case let
				(.callExpression(
					function: leftFunction, parameters: leftParameters, type: leftType),
				 .callExpression(
					function: rightFunction, parameters: rightParameters, type: rightType)):

				return leftFunction.matches(rightFunction, &matches) &&
					leftParameters.matches(rightParameters, &matches) && (leftType == rightType)
			case let
				(.literalIntExpression(value: leftValue),
				 .literalIntExpression(value: rightValue)):

				return leftValue == rightValue
			case let
				(.literalDoubleExpression(value: leftValue),
				 .literalDoubleExpression(value: rightValue)):

				return leftValue == rightValue
			case let
				(.literalBoolExpression(value: leftValue),
				 .literalBoolExpression(value: rightValue)):

				return leftValue == rightValue
			case let
				(.literalStringExpression(value: leftValue),
				 .literalStringExpression(value: rightValue)):

				return leftValue == rightValue
			case (.nilLiteralExpression, .nilLiteralExpression):
				return true
			case let
				(.interpolatedStringLiteralExpression(expressions: leftExpressions),
				 .interpolatedStringLiteralExpression(expressions: rightExpressions)):

				var result = true
				for (leftExpression, rightExpression) in zip(leftExpressions, rightExpressions) {
					result = result && leftExpression.matches(rightExpression, &matches)
				}
				return result
			case let
				(.tupleExpression(pairs: leftPairs),
				 .tupleExpression(pairs: rightPairs)):

				var result = true
				for (leftPair, rightPair) in zip(leftPairs, rightPairs) {
					result = result && leftPair.expression.matches(rightPair.expression, &matches)
						&& leftPair.name == rightPair.name
				}
				return result
			default:
				return false
			}
		}
	}
}

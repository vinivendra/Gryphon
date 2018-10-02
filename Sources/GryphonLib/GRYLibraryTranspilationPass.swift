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
}

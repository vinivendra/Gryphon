//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// gryphon output: Sources/GryphonLib/TranspilationContext.swiftAST
// gryphon output: Sources/GryphonLib/TranspilationContext.gryphonASTRaw
// gryphon output: Sources/GryphonLib/TranspilationContext.gryphonAST
// gryphon output: Bootstrap/TranspilationContext.kt

// declaration: import kotlin.system.*

public class TranspilationContext {
	/// The global context is used for information that should be accessible globally, such as
	/// standard library templates (which can be calculated once and are the same every time).
	static let globalContext = TranspilationContext()

	/// Normal contexts should be initialized based on the pre-existing global information, using
	/// the public `init(indentationString:)` method. This method is only for initializing the
	/// global context.
	private init() {
		self.indentationString = ""
		self.templates = []
	}

	public init(indentationString: String) {
		do {
			try Utilities.updateLibraryFiles()
		}
		catch let error {
			fatalError("Failed to initialize standard library templates!\n\(error)")
		}

		self.templates = TranspilationContext.globalContext.templates.toMutableList()
		self.indentationString = indentationString
	}

	//
	var indentationString: String

	//
	public struct TranspilationTemplate {
		let expression: Expression
		let string: String
	}

	var templates: MutableList<TranspilationTemplate> = []

	public func addTemplate(_ template: TranspilationTemplate) {
		templates.insert(template, at: 0)
	}

	///
	/// This variable is used to store enum definitions in order to allow the translator
	/// to translate them as sealed classes (see the `translate(dotSyntaxCallExpression)` method).
	///
	private(set) var sealedClasses: MutableList<String> = []

	public func addSealedClass(_ className: String) {
		sealedClasses.append(className)
	}

	///
	/// This variable is used to store enum definitions in order to allow the translator
	/// to translate them as enum classes (see the `translate(dotSyntaxCallExpression)` method).
	///
	private(set) var enumClasses: MutableList<String> = []

	public func addEnumClass(_ className: String) {
		enumClasses.append(className)
	}

	///
	/// This variable is used to store protocol definitions in order to allow the translator
	/// to translate conformances to them correctly (instead of as class inheritances).
	///
	private(set) var protocols: MutableList<String> = []

	public func addProtocol(_ protocolName: String) {
		protocols.append(protocolName)
	}

	/// Stores information on how a Swift function should be translated into Kotlin, including what
	/// its prefix should be and what its parameters should be named. The `swiftAPIName` and the
	/// `type` properties are used to look up the right function translation, and they should match
	/// declarationReferences that reference this function.
	/// This is used, for instance, to translate a function to Kotlin using the internal parameter
	/// names instead of Swift's API label names, improving correctness and readability of the
	/// translation. The information has to be stored because declaration references don't include
	/// the internal parameter names, only the API names.
	public struct FunctionTranslation {
		let swiftAPIName: String
		let typeName: String
		let prefix: String
		let parameters: MutableList<String>
	}

	private var functionTranslations: MutableList<FunctionTranslation> = []

	public func addFunctionTranslation(_ newValue: FunctionTranslation) {
		functionTranslations.append(newValue)
	}

	public func getFunctionTranslation(forName name: String, typeName: String)
		-> FunctionTranslation?
	{
		// Functions with unnamed parameters here are identified only by their prefix. For instance
		// `f(_:_:)` here is named `f` but has been stored earlier as `f(_:_:)`.
		for functionTranslation in functionTranslations {
			if functionTranslation.swiftAPIName.hasPrefix(name),
				functionTranslation.typeName == typeName
			{
				return functionTranslation
			}
		}

		return nil
	}

	// TODO: These records should probably go in a Context class of some kind
	/// Stores pure functions so we can reference them later
	private var pureFunctions: MutableList<FunctionDeclaration> = []

	public func recordPureFunction(_ newValue: FunctionDeclaration) {
		pureFunctions.append(newValue)
	}

	public func isReferencingPureFunction(
		_ callExpression: CallExpression)
		-> Bool
	{
		var finalCallExpression = callExpression.function
		while true {
			if let nextCallExpression = finalCallExpression as? DotExpression {
				finalCallExpression = nextCallExpression.rightExpression
			}
			else {
				break
			}
		}

		if let declarationExpression = finalCallExpression as? DeclarationReferenceExpression {
			for functionDeclaration in pureFunctions {
				if declarationExpression.identifier.hasPrefix(functionDeclaration.prefix),
					declarationExpression.typeName == functionDeclaration.functionType
				{
					return true
				}
			}
		}

		return false
	}
}

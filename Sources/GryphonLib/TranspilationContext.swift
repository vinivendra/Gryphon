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

// gryphon insert: import kotlin.system.*

public class TranspilationContext {
	let indentationString: String
	let defaultFinal: Bool

	/// The global context is used for information that should be accessible globally, such as
	/// the Gryphon templates library (which can be calculated once and are the same every time).
	static let globalContext = TranspilationContext()

	/// Normal contexts should be initialized based on the pre-existing global information, using
	/// the public `init(indentationString:)` method. This method is only for initializing the
	/// global context.
	private init() {
		self.indentationString = ""
		self.defaultFinal = false
		self.templates = []
	}

	public init(indentationString: String, defaultFinal: Bool) {
		do {
			try Utilities.processGryphonTemplatesLibrary()
		}
		catch let error {
			fatalError("Failed to initialize the Gryphon templates library!\n\(error)")
		}

		self.templates = TranspilationContext.globalContext.templates.toMutableList()
		self.indentationString = indentationString
		self.defaultFinal = defaultFinal
	}

	// MARK: - Templates

	//
	public struct TranspilationTemplate {
		let expression: Expression
		let string: String
	}

	var templates: MutableList<TranspilationTemplate> = []

	public func addTemplate(_ template: TranspilationTemplate) {
		templates.insert(template, at: 0)
	}

	// MARK: - Declaration records

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

	// MARK: - Function translations

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
		let parameters: List<String>
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

	// MARK: - Pure functions

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

	// MARK: - Swift versions

	/// Currently supported versions. If 5.1 is supported, 5.1.x will be too.
	private static let supportedVersions: List = [
		"5.1",
	]

	private static var chosenToolchainName: String?
	private static var chosenSwiftVersion: String?

	/// Check if the given toolchain uses a supported version of Swift. If it is, set the chosen
	/// toolchain and the chosen Swift version.
	public static func setChosenToolchain(_ toolchain: String?) throws {
		let swiftVersion = try checkToolchainSupport(toolchain)
		chosenToolchainName = toolchain
		chosenSwiftVersion = swiftVersion
	}

	/// Returns the name of the chosen toolchain, which is set and validated by the
	/// `setChosenToolchain()` method.
	public static func getChosenToolchain() -> String? {
		return chosenToolchainName
	}

	/// Returns the Swift version currently being used to dump the ASTs. This value is set and
	/// validated by the `setChosenToolchain()` method.
	public static func getSwiftVersion() -> String? {
		return chosenSwiftVersion
	}

	/// Checks if the given toolchain uses a supported version of Swift. If it does, return that
	/// Swift version. If it doesn't, throw an error.
	@discardableResult
	static func checkToolchainSupport(_ toolchain: String?) throws -> String {
		let arguments: List<String>
		if let toolchain = toolchain {
			arguments = ["xcrun", "--toolchain", toolchain, "swift", "--version"]
		}
		else {
			arguments = ["xcrun", "swift", "--version"]
		}

		let swiftVersionCommandResult = Shell.runShellCommand(arguments)

		guard swiftVersionCommandResult.status == 0 else {
			throw GryphonError(errorMessage: "Unable to determine Swift version:\n" +
				swiftVersionCommandResult.standardOutput +
				swiftVersionCommandResult.standardError)
		}

		// The output is expected to be something like
		// "Apple Swift version 5.1 (swift-5.1-RELEASE)"
		var swiftVersion = swiftVersionCommandResult.standardOutput
		let prefixToRemove = swiftVersion.prefix { !$0.isNumber }
		swiftVersion = String(swiftVersion.dropFirst(prefixToRemove.count))
		swiftVersion = String(swiftVersion.prefix { $0 != " " })

		guard supportedVersions.contains(where: { $0.hasPrefix(swiftVersion) }) else {
			var errorMessage = ""

			if let toolchain = toolchain {
				errorMessage += "Swift version \(swiftVersion) (from toolchain \(toolchain)) " +
					"is not supported.\n"
			}
			else {
				errorMessage += "Swift version \(swiftVersion) is not supported.\n"
			}

			let supportedVersionsString = supportedVersions.joined(separator: ", ")
			errorMessage +=
				"Currently supported Swift versions: \(supportedVersionsString).\n" +
				"You can use the `--toolchain=<toolchain name>` option to choose a toolchain " +
				"with a supported Swift version."

			throw GryphonError(errorMessage: errorMessage)
		}

		return swiftVersion
	}
}

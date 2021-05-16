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

public class TranspilationContext {
	let indentationString: String
	let defaultsToFinal: Bool
	let xcodeProjectPath: String?
	let target: String?
	/// Absolute paths to any files included in the compilation, as well as any other `swiftc`
	/// arguments (except for the SDK path, which should be set in `absolutePathToSDK`).
	/// May be updated if we try to re-init an Xcode project to look for new Swift files.
	var swiftCompilationArguments: List<String>
	/// The path to the SDK that should be used, if explicitly set by an argument or from a file.
	/// If it's `nil`, `getArgumentsForSourceKit` will attempt to fetch the default macOS SDK.
	/// May be updated if we try to re-init an Xcode project to look for new Swift files.
	var absolutePathToSDK: String?

	#if swift(>=5.4)
		static let swiftSyntaxVersion = "5.4"
	#elseif swift(>=5.3)
		static let swiftSyntaxVersion = "5.3"
	#else
		static let swiftSyntaxVersion = "5.2"
	#endif

	static private var baseContext: TranspilationContext?

	/// The base context is used for information that all transpilation contexts should contain,
	/// such as the Gryphon templates library (which can be calculated once and is the same every
	/// time). All transpilation contexts are initialized with the information from the base
	/// context.
	static internal func getBaseContext() throws -> TranspilationContext {
		if let result = baseContext {
			return result
		}
		else {
			let result = try TranspilationContext()
			try Compiler.processGryphonTemplatesLibrary(for: result)
			baseContext = result
			return result
		}
	}

	/// Normal contexts should be initialized using the correct base context, which is done with the
	/// the public `init` method. This method is only for initializing the base contexts themselves.
	private init() throws {
		self.indentationString = ""
		self.defaultsToFinal = false
		self.templates = []
		self.xcodeProjectPath = nil
		self.target = nil
		self.swiftCompilationArguments = [SupportingFile.gryphonTemplatesLibrary.absolutePath]
		self.absolutePathToSDK = nil
	}

	public init(
		indentationString: String,
		defaultsToFinal: Bool,
		xcodeProjectPath: String?,
		target: String?,
		swiftCompilationArguments: List<String>,
		absolutePathToSDK: String?)
		throws
	{
		self.indentationString = indentationString
		self.defaultsToFinal = defaultsToFinal
		self.xcodeProjectPath = xcodeProjectPath
		self.target = target
		self.templates = try TranspilationContext
			.getBaseContext()
			.templates
			.toMutableList()
		self.swiftCompilationArguments = swiftCompilationArguments
		self.absolutePathToSDK = absolutePathToSDK
	}

	// MARK: - Templates

	//
	public struct TranspilationTemplate {
		let swiftExpression: Expression
		let templateExpression: Expression
	}

	var templates: MutableList<TranspilationTemplate> = []

	public func addTemplate(_ template: TranspilationTemplate) {
		templates.insert(template, at: 0)
	}

	// MARK: - Declaration records

	/// This variable is used to store enum definitions in order to allow the translator
	/// to translate them as sealed classes (see the `translate(dotSyntaxCallExpression)` method).
	/// Uses enum names as keys, and the declarations themselves as values.
	private var sealedClasses: Atomic<MutableMap<String, EnumDeclaration>> = Atomic([:])

	/// This variable is used to store enum definitions in order to allow the translator
	/// to translate them as enum classes (see the `translate(dotSyntaxCallExpression)` method).
	/// Uses enum names as keys, and the declarations themselves as values.
	private var enumClasses: Atomic<MutableMap<String, EnumDeclaration>> = Atomic([:])

	public func addEnumClass(_ declaration: EnumDeclaration) {
		enumClasses.mutateAtomically { $0[declaration.enumName] = declaration }
	}

	public func addSealedClass(_ declaration: EnumDeclaration) {
		sealedClasses.mutateAtomically { $0[declaration.enumName] = declaration }
	}

	/// Gets an enum class with the given name, if one was recorded
	public func getEnumClass(named name: String) -> EnumDeclaration? {
		return enumClasses.atomic[name]
	}

	/// Gets a sealed class with the given name, if one was recorded
	public func getSealedClass(named name: String) -> EnumDeclaration? {
		return sealedClasses.atomic[name]
	}

	/// Gets an enum class or a sealed class with the given name, if one was recorded
	public func getEnum(named name: String) -> EnumDeclaration? {
		return enumClasses.atomic[name] ?? sealedClasses.atomic[name]
	}

	/// Checks if an enum class with the given name was recorded
	public func hasEnumClass(named name: String) -> Bool {
		return getEnumClass(named: name) != nil
	}

	/// Checks if a sealed class with the given name was recorded
	public func hasSealedClass(named name: String) -> Bool {
		return getSealedClass(named: name) != nil
	}

	/// Checks if an enum class or a sealed class with the given name was recorded
	public func hasEnum(named name: String) -> Bool {
		return getEnum(named: name) != nil
	}

	///
	/// This variable is used to store protocol definitions in order to allow the translator
	/// to translate conformances to them correctly (instead of as class inheritances).
	///
	internal var protocols: Atomic<MutableList<String>> = Atomic([])

	public func addProtocol(_ protocolName: String) {
		protocols.mutateAtomically { $0.append(protocolName) }
	}

	///
	/// This variable is used to store the inheritances (superclasses and protocols) of each type.
	/// Keys correspond to the full type name (e.g. `A.B.C`), values correspond to its
	/// inheritances.
	///
	private var inheritances: Atomic<MutableMap<String, List<String>>> = Atomic([:])

	/// Stores the inheritances for a given type. The type's name should include its parent
	/// types, e.g. `A.B.C` instead of just `C`.
	public func addInheritances(
		forFullType typeName: String,
		inheritances typeInheritances: List<String>)
	{
		inheritances.mutateAtomically { $0[typeName] = typeInheritances }
	}

	/// Gets the inheritances for a given type. The type's name should include its parent
	/// types, e.g. `A.B.C` instead of just `C`.
	public func getInheritance(forFullType typeName: String) -> List<String>? {
		return inheritances.atomic[typeName]
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
		let parameters: List<FunctionParameter>
	}

	private var functionTranslations: Atomic<MutableList<FunctionTranslation>> = Atomic([])

	public func addFunctionTranslation(_ newValue: FunctionTranslation) {
		functionTranslations.mutateAtomically { $0.append(newValue) }
	}

	public func getFunctionTranslation(forName name: String, typeName: String)
		-> FunctionTranslation?
	{
		// Functions with unnamed parameters here are identified only by their prefix. For instance
		// `f(_:_:)` here is named `f` but has been stored earlier as `f(_:_:)`.
		let allTranslations = functionTranslations.atomic
		for functionTranslation in allTranslations {
			// Avoid confusions with Void and ()
			let translationType = functionTranslation.typeName
				.replacingOccurrences(of: "Void", with: "()")
				.replacingOccurrences(of: "@autoclosure", with: "")
				.replacingOccurrences(of: "@escaping", with: "")
				.replacingOccurrences(of: " ", with: "")
				.replacingOccurrences(of: "throws", with: "")
			let functionType = typeName
				.replacingOccurrences(of: "Void", with: "()")
				.replacingOccurrences(of: "@autoclosure", with: "")
				.replacingOccurrences(of: "@escaping", with: "")
				.replacingOccurrences(of: " ", with: "")
				.replacingOccurrences(of: "throws", with: "")

			let translationPrefix = functionTranslation.swiftAPIName
				.prefix(while: { $0 != "(" && $0 != "<" })
			let namePrefix = name.prefix(while: { $0 != "(" && $0 != "<" })

			if translationPrefix == namePrefix,
				translationType == functionType
			{
				return functionTranslation
			}
		}

		return nil
	}

	// MARK: - Pure functions

	/// Stores pure functions so we can reference them later
	private var pureFunctions: Atomic<MutableList<FunctionDeclaration>> = Atomic([])

	public func recordPureFunction(_ newValue: FunctionDeclaration) {
		pureFunctions.mutateAtomically { $0.append(newValue) }
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
			let allPureFunctions = pureFunctions.atomic
			for functionDeclaration in allPureFunctions {
				if declarationExpression.identifier.hasPrefix(functionDeclaration.prefix),
					declarationExpression.typeName == functionDeclaration.functionType
				{
					return true
				}
			}
		}

		return false
	}

	// MARK: - Swift compiler arguments

	/// Returns all the necessary arguments for a SourceKit request,
	/// including "-D", "GRYPHON", "-sdk" and the SDK path. If no path was explicitly set (in
	/// `absolutePathToSDK`) and we're on macOS, tries to find the default macOS SDK.
	func getArgumentsForSourceKit() throws -> MutableList<String> {
		let mutableArguments = swiftCompilationArguments.toMutableList()
		if let sdkPath = try absolutePathToSDK ?? TranspilationContext.getDefaultSDKPath() {
			mutableArguments.append("-sdk")
			mutableArguments.append(sdkPath)
		}
		if !mutableArguments.contains(collection: ["-D", "GRYPHON"]) {
			mutableArguments.append("-D")
			mutableArguments.append("GRYPHON")
		}
		return mutableArguments
	}

	// MARK: - Default SDK

	private static var defaultSDKPath: String?
	private static let sdkLock = NSLock()

	/// On macOS, tries to find the SDK path using `xcrun`, and throws an error if that fails.
	/// On Linux, returns `nil`.
	static func getDefaultSDKPath() throws -> String? {
		sdkLock.lock()

		defer {
			sdkLock.unlock()
		}

		#if os(macOS)

		if let macOSSDKPath = defaultSDKPath {
			return macOSSDKPath
		}
		else {
			let commandResult = Shell.runShellCommand(
				["xcrun", "--show-sdk-path", "--sdk", "macosx"])
			if commandResult.status == 0 {
				// Drop the \n at the end
				let result = String(commandResult.standardOutput.prefix(while: { $0 != "\n" }))
				defaultSDKPath = result
				return result
			}
			else {
				throw GryphonError(errorMessage: "Unable to get macOS SDK path")
			}
		}

		#else

		return nil

		#endif
	}
}

class Compiler {
	companion object {
		val kotlinCompilerPath: String = if (OS.osName == "Linux") { "/opt/kotlinc/bin/kotlinc" } else { "/usr/local/bin/kotlinc" }
		var log: ((String) -> Unit) = { println(it) }

		public fun shouldLogProgress(value: Boolean) {
			if (value) {
				log = { println(it) }
			}
			else {
				log = { }
			}
		}

		public fun generateSwiftAST(astDump: String): SwiftAST {
			log("\t- Building SwiftAST...")
			val ast: SwiftAST = ASTDumpDecoder(encodedString = astDump).decode()
			return ast
		}

		public fun transpileSwiftAST(inputFile: String): SwiftAST {
			val astDump: String = Utilities.readFile(inputFile)
			return generateSwiftAST(astDump = astDump)
		}
	}
}

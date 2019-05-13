import kotlin.system.exitProcess

fun main(args: Array<String>) {
	if (args.contains("-test")) {
		PrintableAsTreeTest().runAllTests()
		ASTDumpDecoderTest().runAllTests()
		ExtensionsTest().runAllTests()
		UtilitiesTest().runAllTests()
		ShellTest().runAllTests()
	}
	else {
		val result = Driver.run(arguments = args.toMutableList())

		val commandResult = result as? Shell.CommandOutput
		if (commandResult != null) {
			println(commandResult.standardOutput)
			System.err.println(commandResult.standardError)
			exitProcess(commandResult.status)
		}
	}
}

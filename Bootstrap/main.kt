fun main(args: Array<String>) {
	if (args.contains("-test")) {
		PrintableAsTreeTest().runAllTests()
		ASTDumpDecoderTest().runAllTests()
		ExtensionsTest().runAllTests()
		UtilitiesTest().runAllTests()
	}
	else {
		Driver.run(arguments = args.toMutableList())
	}
}

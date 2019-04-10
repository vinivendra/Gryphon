class UtilitiesTest(): Test("UtilitiesTest") {
	override fun runAllTests() {
		testExpandSwiftAbbreviation()
		testFileExtensions()
		testChangeExtension()
		super.runAllTests()
	}

	fun testExpandSwiftAbbreviation() {
		XCTAssertEqual(
			Utilities.expandSwiftAbbreviation("source_file"), "Source File")
		XCTAssertEqual(
			Utilities.expandSwiftAbbreviation("import_decl"), "Import Declaration")
		XCTAssertEqual(
			Utilities.expandSwiftAbbreviation("declref_expr"), "Declaration Reference Expression")
	}

	fun testFileExtensions() {
		XCTAssertEqual(FileExtension.SWIFT_AST_DUMP.rawValue, "swiftASTDump")
		XCTAssertEqual("fileName".withExtension(FileExtension.SWIFT_AST_DUMP), "fileName.swiftASTDump")
	}

	fun testChangeExtension() {
		XCTAssertEqual(
			Utilities.changeExtension("test.txt", FileExtension.SWIFT), 
			"test.swift")
		XCTAssertEqual(
			Utilities.changeExtension("/path/to/test.txt", FileExtension.SWIFT), 
			"/path/to/test.swift")
		XCTAssertEqual(
			Utilities.changeExtension("path/to/test.txt", FileExtension.SWIFT), 
			"path/to/test.swift")
		XCTAssertEqual(
			Utilities.changeExtension("/path/to/test", FileExtension.SWIFT),
			"/path/to/test.swift")
		XCTAssertEqual(
			Utilities.changeExtension("path/to/test", FileExtension.SWIFT),
			"path/to/test.swift")
	}
}

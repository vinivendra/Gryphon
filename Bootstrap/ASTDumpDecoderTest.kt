class ASTDumpDecoderTest(): Test("ASTDumpDecoderTest") {
	override fun runAllTests() {
		testDecoderCanRead()
		super.runAllTests()
	}

	fun testDecoderCanRead() {
		XCTAssert(ASTDumpDecoder(encodedString =
			"(foo)").canReadOpeningParenthesis())
		XCTAssertFalse(ASTDumpDecoder(encodedString =
			"foo)").canReadOpeningParenthesis())

		XCTAssert(ASTDumpDecoder(encodedString =
			") foo").canReadClosingParenthesis())
		XCTAssertFalse(ASTDumpDecoder(encodedString =
			"(foo)").canReadClosingParenthesis())

		XCTAssert(ASTDumpDecoder(encodedString =
			"[0]").canReadOpeningBracket())
		XCTAssertFalse(ASTDumpDecoder(encodedString =
			"0]").canReadOpeningBracket())

		XCTAssert(ASTDumpDecoder(encodedString =
			"] foo").canReadClosingBracket())
		XCTAssertFalse(ASTDumpDecoder(encodedString =
			"[foo]").canReadClosingBracket())

		XCTAssert(ASTDumpDecoder(encodedString =
			"{0 1}").canReadOpeningBrace())
		XCTAssertFalse(ASTDumpDecoder(encodedString =
			"0 1}").canReadOpeningBrace())

		XCTAssert(ASTDumpDecoder(encodedString =
			"} 0 1").canReadClosingBrace())
		XCTAssertFalse(ASTDumpDecoder(encodedString =
			"{0 1}").canReadClosingBrace())

		XCTAssert(ASTDumpDecoder(encodedString =
			"\"foo\")").canReadDoubleQuotedString())
		XCTAssertFalse(ASTDumpDecoder(encodedString =
			"(\"foo\")").canReadDoubleQuotedString())

		XCTAssert(ASTDumpDecoder(encodedString =
			"'foo')").canReadSingleQuotedString())
		XCTAssertFalse(ASTDumpDecoder(encodedString =
			"('foo')").canReadSingleQuotedString())

		XCTAssert(ASTDumpDecoder(encodedString =
			"[foo])").canReadStringInBrackets())
		XCTAssertFalse(ASTDumpDecoder(encodedString =
			"([foo])").canReadStringInBrackets())
	}
}

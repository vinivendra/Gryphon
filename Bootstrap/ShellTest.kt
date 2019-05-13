class ShellTest(): Test("ShellTest") {
    override fun runAllTests() {
        testEcho()
        testSwiftc()
        super.runAllTests()
    }

    fun testEcho() {
        val command = mutableListOf("echo", "foo bar baz")
        val commandResult = Shell.runShellCommand(command)
        if (commandResult == null) {
            XCTFail("Timed out.")
            return
        }
        XCTAssertEqual(commandResult.standardOutput, "foo bar baz\n")
        XCTAssertEqual(commandResult.standardError, "")
        XCTAssertEqual(commandResult.status, 0)
    }

    fun testSwiftc() {
        val command1 = mutableListOf("swiftc", "-dump-ast")
        val command1Result = Shell.runShellCommand(command1)
        if (command1Result == null) {
            XCTFail("Timed out.")
            return
        }
        XCTAssertEqual(command1Result.standardOutput, "")
        XCTAssertEqual(command1Result.standardError, "<unknown>:0: error: no input files\n")
        XCTAssertNotEqual(command1Result.status, 0)

        val command2 = mutableListOf("swiftc", "--help")
        val command2Result = Shell.runShellCommand(command2)
        if (command2Result == null) {
            XCTFail("Timed out.")
            return
        }
        XCTAssert(command2Result.standardOutput.contains("-dump-ast"))
        XCTAssertEqual(command2Result.standardError, "")
        XCTAssertEqual(command2Result.status, 0)
    }
}
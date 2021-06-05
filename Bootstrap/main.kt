//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import kotlin.system.exitProcess

fun main(args: Array<String>) {
    if (args.contains("-test")) {
        ASTDumpDecoderTest().run()
        CompilerTest().run()
        DriverTest().run()
        ExtensionsTest().run()
        IntegrationTest().run()
        LibraryTranspilationTest().run()
        ListTest().run()
        MutableListTest().run()
        MapTest().run()
        MutableMapTest().run()
        PrintableAsTreeTest().run()
        ShellTest().run()
        SourceFileTest().run()
        UtilitiesTest().run()

        // AcceptanceTest().run()

        for (passedTest in XCTestCase.passedTests) {
            println("✅ ${passedTest}: All tests succeeded!")
        }

        if (!XCTestCase.passedTests.isEmpty() && 
            !XCTestCase.failedTests.isEmpty())
        {
            println("")
        }

        for (failedTest in XCTestCase.failedTests) {
            println("🚨 ${failedTest}: Test failed!")
        }
    }
    else {
        try {
            val result = Driver.run(arguments = args.toMutableList())

            val commandResult = result as? Shell.CommandOutput
            if (commandResult != null) {
                println(commandResult.standardOutput)
                System.err.println(commandResult.standardError)
                exitProcess(commandResult.status)
            }
        }
        catch (error: Exception) {
            println(error)
            exitProcess(-1)
        }
    }
}

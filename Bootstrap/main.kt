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
        TranslationResultTest().run()
        UtilitiesTest().run()

        InitializationTest().run()

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

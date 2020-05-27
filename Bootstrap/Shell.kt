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

import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.File
import java.util.concurrent.TimeUnit

public class Shell {
    data class CommandOutput(
        val standardOutput: String,
        val standardError: String,
        val status: Int) { }

    companion object {
        val defaultTimeout: Long = 60

        fun runShellCommand(
            command: String,
            arguments: List<String>, 
            currentFolder: String? = null)
            : CommandOutput
        {
            val commandAndArguments = mutableListOf(command)
            commandAndArguments.addAll(arguments)

            val array = arrayOfNulls<String>(commandAndArguments.size)
            for (index in commandAndArguments.indices) {
                array[index] = commandAndArguments[index]
            }

            val directory: File?
            if (currentFolder != null) {
                directory = File(currentFolder)
            }
            else {
                directory = null
            }

            val processBuilder: ProcessBuilder = ProcessBuilder()
            processBuilder.command(commandAndArguments)
            val process: Process = processBuilder.start()

            process.waitFor()

            val output: StringBuilder = StringBuilder()
            val outputReader: BufferedReader = BufferedReader(
                    InputStreamReader(process.getInputStream()))
            var line: String? = outputReader.readLine()
            while (line != null) {
                output.append(line + "\n")
                line = outputReader.readLine()
            }

            val error: StringBuilder = StringBuilder()
            val errorReader: BufferedReader = BufferedReader(
                    InputStreamReader(process.getErrorStream()))
            line = errorReader.readLine()
            while (line != null) {
                error.append(line + "\n")
                line = errorReader.readLine()
            }

            return CommandOutput(
                standardOutput = output.toString(),
                standardError = error.toString(),
                status = process.exitValue())
        }

        fun runShellCommand(
            arguments: List<String>, 
            currentFolder: String? = null)
            : CommandOutput
        {
            return runShellCommand(
                command = "/usr/bin/env",
                arguments = arguments,
                currentFolder = currentFolder)
        }
    }
}

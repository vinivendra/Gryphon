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
            arguments: MutableList<String>, 
            currentFolder: String? = null, 
            timeout: Long = Shell.defaultTimeout)
            : CommandOutput?
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

            val hasFinished: Boolean = process.waitFor(
                timeout,
                TimeUnit.SECONDS)

            if (!hasFinished) {
                return null
            }

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
            arguments: MutableList<String>, 
            currentFolder: String? = null, 
            timeout: Long = Shell.defaultTimeout)
            : CommandOutput?
        {
            return runShellCommand(
                command = "/usr/bin/env",
                arguments = arguments,
                currentFolder = currentFolder,
                timeout = timeout)
        }
    }
}

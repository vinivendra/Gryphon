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

public class OS {
    companion object {
        val javaOSName = System.getProperty("os.name")
        val osName = if (javaOSName == "Mac OS X") { "macOS" } else { "Linux" }

        val javaArchitecture = System.getProperty("os.arch")
        val architecture = if (javaArchitecture == "x86_64") { "x86_64" }
            else { "i386" }

        val systemIdentifier: String = osName + "-" + architecture

        val kotlinCompilerPath: String = if (osName == "Linux")
            { "/opt/kotlinc/bin/kotlinc" } else
            { "/usr/local/bin/kotlinc" }
    }
}

internal fun TestUtilities.Companion.changeCurrentDirectoryPath(newPath: String) {
    System.setProperty("user.dir", newPath)
}

//
// Copyright 2018 Vinícius Jorge Vendramini
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

import GryphonLib
import Foundation

do {
	let result = try Driver.run(withArguments: MutableList(CommandLine.arguments.dropFirst()))

	if let commandResult = result as? Shell.CommandOutput {
		print(commandResult.standardOutput)
		FileHandle.standardError.write(commandResult.standardError.data(using: .utf8)!)
		exit(commandResult.status)
	}
}
catch let error {
	print(error)
	exit(-1)
}

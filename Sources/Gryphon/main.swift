//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Gryphon - Copyright (2018) Vinícius Jorge Vendramini (“Licensor”)
// Licensed under the Hippocratic License, Version 2.1 (the "License");
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

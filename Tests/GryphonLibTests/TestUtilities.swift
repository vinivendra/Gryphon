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

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

import Foundation

public class OS {
	#if os(macOS)
	static let osName = "macOS"
	#else
	static let osName = "Linux"
	#endif

	#if arch(x86_64)
	static let architecture = "x86_64"
	#elseif arch(i386)
	static let architecture = "i386"
	#endif

	public static let systemIdentifier: String = osName + "-" + architecture

	static let kotlinCompilerPath = (osName == "Linux") ?
		"/opt/kotlinc/bin/kotlinc" :
		"/usr/local/bin/kotlinc"
}

extension TestUtilities {
	static func changeCurrentDirectoryPath(_ newPath: String) {
		let success = FileManager.default.changeCurrentDirectoryPath(newPath)
		assert(success)
	}
}

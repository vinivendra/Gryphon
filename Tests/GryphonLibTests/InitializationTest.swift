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

// gryphon output: Bootstrap/InitializationTest.kt

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

class InitializationTest: XCTestCase {
	// insert: constructor(): super() { }

	public func getClassName() -> String { // annotation: override
		return "InitializationTest"
	}

	/// Tests to be run by the translated Kotlin version.
	public func runAllTests() { // annotation: override
		testInitialization()
	}

	/// Tests to be run when using Swift on Linux
	static var allTests = [ // ignore: ignore
		("testInitialization", testInitialization),
	]

	// MARK: - Tests
	func testInitialization() {
		// Delete old folder
		Utilities.deleteFolder(at: SupportingFile.gryphonBuildFolder)

		// Create a new folder
		try! Driver.run(withArguments: ["init", "-no-xcode"])

		// Check the new folder's contents are right
		do {
			let templatesFileContents =
				try Utilities.readFile(SupportingFile.gryphonTemplatesLibrary.relativePath)
			let xctestFileContents =
				try Utilities.readFile(SupportingFile.gryphonXCTest.relativePath)
			let scriptFileContents =
				try Utilities.readFile(SupportingFile.mapKotlinErrorsToSwift.relativePath)

			if templatesFileContents != gryphonTemplatesLibraryFileContents {
				XCTFail("Library templates file's contents are wrong.")
			}
			if xctestFileContents != gryphonXCTestFileContents {
				XCTFail("Gryphon's XCTest file's contents are wrong.")
			}
			if scriptFileContents != kotlinErrorMapScriptFileContents {
				XCTFail("Error map script contents file's contents are wrong.")
			}

			//
			// Test cleanup
			try! Driver.run(withArguments: ["clean"])
			XCTAssertFalse(
				Utilities.fileExists(at: SupportingFile.gryphonTemplatesLibrary.relativePath))

			// Create the folder again so other testing and development can continue
			try! Driver.run(withArguments: ["init", "-no-xcode"])
		}
		catch let error {
			XCTFail("Gryphon -init failed to read file: \(error)")
			return
		}
	}
}

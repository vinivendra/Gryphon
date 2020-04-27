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

@testable import GryphonLib
import XCTest
import Foundation

class InitializationTest: XCTestCase {
	/// Tests to be run when using Swift on Linux
	static var allTests = [
		("testXcodeInitialization", testXcodeInitialization),
		("testInitialization", testInitialization),
	]

	static let testFolder = ".initTest"

	// MARK: - Tests
	func testXcodeInitialization() {
		if Utilities.fileExists(at: SupportingFile.gryphonBuildFolder) {
			Utilities.deleteFolder(at: SupportingFile.gryphonBuildFolder)
		}

		do {
			// Create a new folder
			try Driver.run(withArguments: ["init", "-xcode"])

			// Check the new folder's contents
			for file in SupportingFile.filesForXcodeInitialization {
				if let contents = file.contents {
					let fileContents = try Utilities.readFile(file.relativePath)
					XCTAssertEqual(fileContents, contents)
				}
			}

			// Test cleanup
			try Driver.run(withArguments: ["clean"])
			XCTAssertFalse(Utilities.fileExists(at: SupportingFile.gryphonBuildFolder))
		}
		catch let error {
			XCTFail("\(error)")
		}
	}

	func testInitialization() {
		if Utilities.fileExists(at: SupportingFile.gryphonBuildFolder) {
			Utilities.deleteFolder(at: SupportingFile.gryphonBuildFolder)
		}

		do {
			// Create a new folder
			try Driver.run(withArguments: ["init"])

			// Check the new folder's contents
			for file in SupportingFile.filesForInitialization {
				if let contents = file.contents {
					let fileContents = try Utilities.readFile(file.relativePath)
					XCTAssertEqual(fileContents, contents)
				}
			}

			// Test cleanup
			try Driver.run(withArguments: ["clean"])
			XCTAssertFalse(Utilities.fileExists(at: SupportingFile.gryphonBuildFolder))
		}
		catch let error {
			XCTFail("\(error)")
		}
	}

	override static func setUp() {
		Utilities.deleteFolder(at: testFolder)
		Utilities.createFolderIfNeeded(at: testFolder)
		TestUtilities.changeCurrentDirectoryPath(testFolder)
	}

	override static func tearDown() {
		TestUtilities.changeCurrentDirectoryPath("..")
		Utilities.deleteFolder(at: testFolder)
	}
}

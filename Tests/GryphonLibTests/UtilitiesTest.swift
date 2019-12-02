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

@testable import GryphonLib
import XCTest

class UtilitiesTest: XCTestCase {
	func testExpandSwiftAbbreviation() {
		XCTAssertEqual(
			Utilities.expandSwiftAbbreviation("source_file"), "Source File")
		XCTAssertEqual(
			Utilities.expandSwiftAbbreviation("import_decl"), "Import Declaration")
		XCTAssertEqual(
			Utilities.expandSwiftAbbreviation("declref_expr"), "Declaration Reference Expression")
        XCTAssertEqual(
            Utilities.expandSwiftAbbreviation("load_expr"), "Load Expression")
        XCTAssertEqual(
            Utilities.expandSwiftAbbreviation("func_decl"), "Function Declaration")
        XCTAssertEqual(
            Utilities.expandSwiftAbbreviation("type_ident"), "Type Identity")
        XCTAssertEqual(
            Utilities.expandSwiftAbbreviation("paren_expr"), "Parentheses Expression")
        XCTAssertEqual(
            Utilities.expandSwiftAbbreviation("brace_stmt"), "Brace Statement")
        XCTAssertEqual(
            Utilities.expandSwiftAbbreviation("var_decl"), "Variable Declaration")
        XCTAssertEqual(
            Utilities.expandSwiftAbbreviation("member_ref_expr"), "Member Reference Expression")
	}

	func testFileExtension() {
		XCTAssertEqual(FileExtension.swiftASTDump.rawValue, "swiftASTDump")
		XCTAssertEqual("fileName".withExtension(.swiftASTDump), "fileName.swiftASTDump")
	}

	func testChangeExtension() {
		XCTAssertEqual(
			Utilities.changeExtension(of: "test.txt", to: .swift),
			"test.swift")
		XCTAssertEqual(
			Utilities.changeExtension(of: "/path/to/test.txt", to: .swift),
			"/path/to/test.swift")
		XCTAssertEqual(
			Utilities.changeExtension(of: "path/to/test.txt", to: .kt),
			"path/to/test.kt")
		XCTAssertEqual(
			Utilities.changeExtension(of: "/path/to/test", to: .xcfilelist),
			"/path/to/test.xcfilelist")
		XCTAssertEqual(
			Utilities.changeExtension(of: "path/to/test", to: .output),
			"path/to/test.output")
	}

    func testGetExtension() {
        XCTAssertEqual(Utilities.getExtension(of: "path/to/test.output"), .output)
        XCTAssertEqual(Utilities.getExtension(of: "test.swift"), .swift)
        XCTAssertEqual(Utilities.getExtension(of: "/path/to/test.kt"), .kt)
    }

    func testPathOfSwiftASTDumpFile() {
        XCTAssertEqual(
            Utilities.pathOfSwiftASTDumpFile(forSwiftFile: "src/path/to/file.swift"),
            ".gryphon/ASTDumps/src/path/to/file.swiftASTDump")
        XCTAssertEqual(
            Utilities.pathOfSwiftASTDumpFile(forSwiftFile: "folder/file.swift"),
            ".gryphon/ASTDumps/folder/file.swiftASTDump")
        XCTAssertEqual(
            Utilities.pathOfSwiftASTDumpFile(forSwiftFile: "file.swift"),
            ".gryphon/ASTDumps/file.swiftASTDump")
    }

    func testPathOfKotlinErrorMapFile() {
        XCTAssertEqual(
            Utilities.pathOfKotlinErrorMapFile(forKotlinFile: "src/path/to/file.kt"),
            ".gryphon/KotlinErrorMaps/src/path/to/file.kotlinErrorMap")
        XCTAssertEqual(
            Utilities.pathOfKotlinErrorMapFile(forKotlinFile: "folder/file.kt"),
            ".gryphon/KotlinErrorMaps/folder/file.kotlinErrorMap")
        XCTAssertEqual(
            Utilities.pathOfKotlinErrorMapFile(forKotlinFile: "file.kt"),
            ".gryphon/KotlinErrorMaps/file.kotlinErrorMap")
    }

    func testGetRelativePath() {
        let currentFolder = Utilities.getCurrentFolder()

        XCTAssertEqual(
            "path/to/file.swift",
            Utilities.getRelativePath(forFile: "path/to/file.swift"))
        XCTAssertEqual(
            "path/to/file.swift",
            Utilities.getRelativePath(forFile: currentFolder + "/path/to/file.swift"))
    }

    func testSplitTypeList() {
        XCTAssertEqual(
            Utilities.splitTypeList("Int, Int, Int, Int"),
            ["Int", "Int", "Int", "Int"])
        XCTAssertEqual(
            Utilities.splitTypeList("Int: Int"),
            ["Int", "Int"])
        XCTAssertEqual(
            Utilities.splitTypeList("Int, Box<Int, Int>, Int"),
            ["Int", "Box<Int, Int>", "Int"])
        XCTAssertEqual(
            Utilities.splitTypeList("Int, [Int: Int], Int"),
            ["Int", "[Int: Int]", "Int"])
        XCTAssertEqual(
            Utilities.splitTypeList("Int, (Int, Int), Int"),
            ["Int", "(Int, Int)", "Int"])
        XCTAssertEqual(
            Utilities.splitTypeList("Int: Box<Int, Int>"),
            ["Int", "Box<Int, Int>"])
    }

    func testIsInEnvelopingParentheses() {
        XCTAssert(Utilities.isInEnvelopingParentheses("(Int)"))
        XCTAssert(Utilities.isInEnvelopingParentheses("(Int, Int)"))
        XCTAssert(Utilities.isInEnvelopingParentheses("(Int, (Int))"))
        XCTAssert(Utilities.isInEnvelopingParentheses("((Int), (Int))"))
        XCTAssert(Utilities.isInEnvelopingParentheses("((Int), Int)"))

        XCTAssertFalse(Utilities.isInEnvelopingParentheses("(Int) -> (Int)"))
        XCTAssertFalse(Utilities.isInEnvelopingParentheses("(Int) -> (Int, Int)"))
        XCTAssertFalse(Utilities.isInEnvelopingParentheses("(Int, Int) -> (Int, Int)"))
    }

    func testGetTypeMapping() {
        XCTAssertEqual(Utilities.getTypeMapping(for: "Bool"), "Boolean")
        XCTAssertEqual(Utilities.getTypeMapping(for: "Error"), "Exception")
        XCTAssertEqual(Utilities.getTypeMapping(for: "String.Index"), "Int")
        XCTAssertEqual(Utilities.getTypeMapping(for: "Range<String.Index>"), "IntRange")

        XCTAssertEqual(Utilities.getTypeMapping(for: "Asdf"), nil)
    }

    func testGetCurrentFolder() {
        XCTAssert(Utilities.getCurrentFolder().hasSuffix("Gryphon"))
    }

    func testGetFiles() {
        let allSwiftFiles = Utilities.getFiles(
            inDirectory: "Sources/GryphonLib",
            withExtension: .swift)
        let someSwiftFiles = Utilities.getFiles(
            ["Utilities", "SharedUtilities"],
            inDirectory: "Sources/GryphonLib",
            withExtension: .swift)
        let kotlinFiles = Utilities.getFiles(
            inDirectory: "Sources/GryphonLib",
            withExtension: .kt)

        XCTAssert(allSwiftFiles.contains { $0.hasSuffix("/Utilities.swift") })
        XCTAssert(allSwiftFiles.contains { $0.hasSuffix("/SharedUtilities.swift") })
        XCTAssert(allSwiftFiles.contains { $0.hasSuffix("/TranspilationPass.swift") })

        XCTAssert(someSwiftFiles.contains { $0.hasSuffix("/Utilities.swift") })
        XCTAssert(someSwiftFiles.contains { $0.hasSuffix("/SharedUtilities.swift") })
        XCTAssert(someSwiftFiles.count == 2)

        XCTAssert(kotlinFiles.isEmpty)
    }
}

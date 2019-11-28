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

import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
	return [
		testCase(AcceptanceTest.allTests),
		testCase(ASTDumpDecoderTest.allTests),
		testCase(BootstrappingTest.allTests),
		testCase(ExtensionsTest.allTests),
		testCase(IntegrationTest.allTests),
		testCase(PrintableAsTreeTest.allTests),
		testCase(ShellTest.allTests),
		testCase(FixedArrayTest.allTests),
		testCase(MutableArrayTest.allTests),
		testCase(MutableDictionaryTest.allTests),

		// Initialization tests reset the stdlib templates file, so they need to be at the end.
		testCase(InitializationTests.allTests),
	]
}
#endif

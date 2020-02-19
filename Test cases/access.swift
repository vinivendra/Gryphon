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

// gryphon output: Test cases/Bootstrap Outputs/access.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/access.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/access.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/access.kt

// Check access modifiers inside classes
class A1 {
	var a1 = 0
	public var a2 = 0
	internal var a3 = 0
	fileprivate var a4 = 0
	private var a5 = 0

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

public class A2 {
	var a1 = 0
	public var a2 = 0
	internal var a3 = 0
	fileprivate var a4 = 0
	private var a5 = 0

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

internal class A3 {
	var a1 = 0
	public var a2 = 0
	internal var a3 = 0
	fileprivate var a4 = 0
	private var a5 = 0

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

fileprivate class A4 {
	var a1 = 0
	public var a2 = 0
	internal var a3 = 0
	fileprivate var a4 = 0
	private var a5 = 0

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

private class A5 {
	var a1 = 0
	public var a2 = 0
	internal var a3 = 0
	fileprivate var a4 = 0
	private var a5 = 0

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

// Check access modifiers for static members
class A6 {
	static var a1 = 0
	public static var a2 = 0
	internal static var a3 = 0
	fileprivate static var a4 = 0
	private static var a5 = 0

	static func b1() { }
	public static func b2() { }
	internal static func b3() { }
	fileprivate static func b4() { }
	private static func b5() { }
}

public class A7 {
	static var a1 = 0
	public static var a2 = 0
	internal static var a3 = 0
	fileprivate static var a4 = 0
	private static var a5 = 0

	static func b1() { }
	public static func b2() { }
	internal static func b3() { }
	fileprivate static func b4() { }
	private static func b5() { }
}

internal class A8 {
	static var a1 = 0
	public static var a2 = 0
	internal static var a3 = 0
	fileprivate static var a4 = 0
	private static var a5 = 0

	static func b1() { }
	public static func b2() { }
	internal static func b3() { }
	fileprivate static func b4() { }
	private static func b5() { }
}

fileprivate class A9 {
	static var a1 = 0
	public static var a2 = 0
	internal static var a3 = 0
	fileprivate static var a4 = 0
	private static var a5 = 0

	static func b1() { }
	public static func b2() { }
	internal static func b3() { }
	fileprivate static func b4() { }
	private static func b5() { }
}

private class A10 {
	static var a1 = 0
	public static var a2 = 0
	internal static var a3 = 0
	fileprivate static var a4 = 0
	private static var a5 = 0

	static func b1() { }
	public static func b2() { }
	internal static func b3() { }
	fileprivate static func b4() { }
	private static func b5() { }
}

// Check access modifiers inside structs
struct B1 {
	let a1 = 0
	public let a2 = 0
	internal let a3 = 0
	fileprivate let a4 = 0
	private let a5 = 0

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

public struct B2 {
	let a1 = 0
	public let a2 = 0
	internal let a3 = 0
	fileprivate let a4 = 0
	private let a5 = 0

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

internal struct B3 {
	let a1 = 0
	public let a2 = 0
	internal let a3 = 0
	fileprivate let a4 = 0
	private let a5 = 0

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

fileprivate struct B4 {
	let a1 = 0
	public let a2 = 0
	internal let a3 = 0
	fileprivate let a4 = 0
	private let a5 = 0

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

private struct B5 {
	let a1 = 0
	public let a2 = 0
	internal let a3 = 0
	fileprivate let a4 = 0
	private let a5 = 0

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

// Check access modifiers inside enums
enum C1 {
	case a

	var a1: Int { return 0 }
	public var a2: Int { return 0 }
	internal var a3: Int { return 0 }
	fileprivate var a4: Int { return 0 }
	private var a5: Int { return 0 }

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

public enum C2 {
	case a

	var a1: Int { return 0 }
	public var a2: Int { return 0 }
	internal var a3: Int { return 0 }
	fileprivate var a4: Int { return 0 }
	private var a5: Int { return 0 }

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

internal enum C3 {
	case a

	var a1: Int { return 0 }
	public var a2: Int { return 0 }
	internal var a3: Int { return 0 }
	fileprivate var a4: Int { return 0 }
	private var a5: Int { return 0 }

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

fileprivate enum C4 {
	case a

	var a1: Int { return 0 }
	public var a2: Int { return 0 }
	internal var a3: Int { return 0 }
	fileprivate var a4: Int { return 0 }
	private var a5: Int { return 0 }

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

private enum C5 {
	case a

	var a1: Int { return 0 }
	public var a2: Int { return 0 }
	internal var a3: Int { return 0 }
	fileprivate var a4: Int { return 0 }
	private var a5: Int { return 0 }

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

// Check that access modifiers inside protocols are omitted
protocol D1 {
	var a: Int { get }
	func b()
}

public protocol D2 {
	var a: Int { get }
	func b()
}

internal protocol D3 {
	var a: Int { get }
	func b()
}

fileprivate protocol D4 {
	var a: Int { get }
	func b()
}

private protocol D5 {
	var a: Int { get }
	func b()
}

// Check that access modifiers inside extensions are kept
extension String {
	var a1: Int { return 0 }
	public var a2: Int { return 0 }
	internal var a3: Int { return 0 }
	fileprivate var a4: Int { return 0 }
	private var a5: Int { return 0 }

	func b1() { }
	public func b2() { }
	internal func b3() { }
	fileprivate func b4() { }
	private func b5() { }
}

// Check that access modifiers in top-level variables are omitted
var a1: Int = 0
public var a2: Int = 0
internal var a3: Int = 0
fileprivate var a4: Int = 0
private var a5: Int = 0

// Check that annotations are correctly interpreted and treated as access modifiers
public class A11 {
	private var a1 = 0 // gryphon annotation: public
	private var a2 = 0 // gryphon annotation: internal
	private var a3 = 0 // gryphon annotation: protected
	internal var a4 = 0 // gryphon annotation: private

	private func b1() { } // gryphon annotation: public
	private func b2() { } // gryphon annotation: internal
	private func b3() { } // gryphon annotation: protected
	internal func b4() { } // gryphon annotation: private
}

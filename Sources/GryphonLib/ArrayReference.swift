/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

public protocol GRYIgnore { }

public class ArrayReference<Element>: GRYIgnore,
	ExpressibleByArrayLiteral, CustomStringConvertible, CustomDebugStringConvertible,
	RandomAccessCollection, MutableCollection, RangeReplaceableCollection
{
	public var array: [Element]

	public init(array: [Element]) {
		self.array = array
	}

	public func copy() -> ArrayReference<Element> {
		return ArrayReference(array: array)
	}

	// Expressible By Array Literal
	public typealias ArrayLiteralElement = Element

	public required init(arrayLiteral elements: Element...) {
		self.array = elements
	}

	// ...
	public subscript (_ index: Int) -> Element {
		get {
			return array[index]
		}
		set {
			array[index] = newValue
		}
	}

	// Custom (Debug) String Convertible
	public var description: String {
		return array.description
	}

	public var debugDescription: String {
		return array.debugDescription
	}

	// Collection
	public var startIndex: Int {
		return array.startIndex
	}

	public var endIndex: Int {
		return array.endIndex
	}

	public func index(after i: Int) -> Int {
		return i + 1
	}

	// Bidirectional Collection
	public func index(before i: Int) -> Int {
		return i - 1
	}

	// Range Replaceable Collection
	public func append<S>(contentsOf newElements: S) where S: Sequence, Element == S.Element {
		self.array.append(contentsOf: newElements)
	}

	public required init<S>(_ elements: S) where S: Sequence, Element == S.Element {
		self.array = []
	}

	public required init() {
		self.array = []
	}

	//
	public func append(_ newElement: Element) {
		array.append(newElement)
	}
}

extension ArrayReference: Equatable where Element: Equatable {
	public static func == (lhs: ArrayReference, rhs: ArrayReference) -> Bool {
		return lhs.array == rhs.array
	}
}

extension ArrayReference {
	public static func + <T>(lhs: ArrayReference<T>, rhs: ArrayReference<T>) -> ArrayReference<T> {
		return ArrayReference<T>(array: lhs.array + rhs.array)
	}

	public static func + <T>(lhs: ArrayReference<T>, rhs: [T]) -> ArrayReference<T> {
		return ArrayReference<T>(array: lhs.array + rhs)
	}

	public static func + <T>(lhs: [T], rhs: ArrayReference<T>) -> ArrayReference<T> {
		return ArrayReference<T>(array: lhs + rhs.array)
	}
}

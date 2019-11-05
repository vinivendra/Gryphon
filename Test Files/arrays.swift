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

// gryphon output: Test Files/Bootstrap Outputs/arrays.swiftAST
// gryphon output: Test Files/Bootstrap Outputs/arrays.gryphonASTRaw
// gryphon output: Test Files/Bootstrap Outputs/arrays.gryphonAST
// gryphon output: Test Files/Bootstrap Outputs/arrays.kt

/// According to http://swiftdoc.org/v4.2/type/Array/hierarchy/
/// (link found via https://www.raywenderlich.com/139591/building-custom-collection-swift)
/// the Array type in Swift conforms exactly to these protocols,
/// plus CustomReflectable (which is beyond Gryphon's scope for now).
public final class ArrayClass<Element>: // kotlin: ignore
	ExpressibleByArrayLiteral, CustomStringConvertible, CustomDebugStringConvertible,
	RandomAccessCollection, MutableCollection, RangeReplaceableCollection
{
	public typealias Buffer = [Element]

	public var array: Buffer

	public init(_ array: Buffer) {
		self.array = array
	}

	public init<T>(_ arrayClass: ArrayClass<T>) {
		self.array = arrayClass.array as! Buffer
	}

	public func `as`<CastedType>(
		_ type: ArrayClass<CastedType>.Type)
		-> ArrayClass<CastedType>?
	{
		if let castedArray = self.array as? [CastedType] {
			return ArrayClass<CastedType>(castedArray)
		}
		else {
			return nil
		}
	}

	public func copy() -> ArrayClass<Element> {
		return ArrayClass(array)
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

	public var isEmpty: Bool {
		return array.isEmpty
	}

	public var first: Element? {
		return array.first
	}

	public var last: Element? {
		return array.last
	}

	// Bidirectional Collection
	public func index(before i: Int) -> Int {
		return i - 1
	}

	// Range Replaceable Collection
	public func append<S>(contentsOf newElements: S) where S: Sequence, Element == S.Element {
		self.array.append(contentsOf: newElements)
	}

	public init<S>(_ sequence: S) where Element == S.Element, S: Sequence {
		self.array = Array(sequence)
	}

	public required init() {
		self.array = []
	}

	//
	public func append(_ newElement: Element) {
		array.append(newElement)
	}

	public func appending(_ newElement: Element) -> ArrayClass<Element> {
		return ArrayClass<Element>(self.array + [newElement])
	}

	public func insert(_ newElement: Element, at i: Index) {
		array.insert(newElement, at: i)
	}

	public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> ArrayClass<Element> {
		return try ArrayClass(self.array.filter(isIncluded))
	}

	public func map<T>(_ transform: (Element) throws -> T) rethrows -> ArrayClass<T> {
		return try ArrayClass<T>(self.array.map(transform))
	}

	public func compactMap<T>(_ transform: (Element) throws -> T?) rethrows -> ArrayClass<T> {
		return try ArrayClass<T>(self.array.compactMap(transform))
	}

	public func flatMap<SegmentOfResult>(
		_ transform: (Element) throws -> SegmentOfResult)
		rethrows -> ArrayClass<SegmentOfResult.Element>
		where SegmentOfResult: Sequence
	{
		return try ArrayClass<SegmentOfResult.Element>(array.flatMap(transform))
	}

	@inlinable
	public func sorted(
		by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows
		-> ArrayClass<Element>
	{
		return ArrayClass(try array.sorted(by: areInIncreasingOrder))
	}

	public func appending<S>(contentsOf newElements: S) -> ArrayClass<Element>
		where S: Sequence, Element == S.Element
	{
		return ArrayClass<Element>(self.array + newElements)
	}

	@discardableResult
	public func removeFirst() -> Element {
		return array.removeFirst()
	}

	@discardableResult
	public func removeLast() -> Element {
		return array.removeLast()
	}

	public func reverse() {
		array.reverse()
	}

	public var indices: Range<Int> {
		return array.indices
	}
}

extension ArrayClass: Equatable where Element: Equatable { // kotlin: ignore
	public static func == (lhs: ArrayClass, rhs: ArrayClass) -> Bool {
		return lhs.array == rhs.array
	}

	//
	public func index(of element: Element) -> Int? {
		return array.index(of: element)
	}
}

extension ArrayClass: Hashable where Element: Hashable { // kotlin: ignore
	public func hash(into hasher: inout Hasher) {
		array.hash(into: &hasher)
	}
}

extension ArrayClass: Codable where Element: Codable { // kotlin: ignore
	public func encode(to encoder: Encoder) throws {
		try array.encode(to: encoder)
	}

	public convenience init(from decoder: Decoder) throws {
		try self.init(Buffer(from: decoder))
	}
}

extension ArrayClass where Element: Comparable { // kotlin: ignore
	@inlinable
	public func sorted() -> ArrayClass<Element> {
		return ArrayClass(array.sorted())
	}
}

public struct FixedArray<Element>: // kotlin: ignore
	ExpressibleByArrayLiteral, CustomStringConvertible, CustomDebugStringConvertible,
	RandomAccessCollection
{
	public typealias Buffer = [Element]

	public let array: Buffer

	public init(_ array: Buffer) {
		self.array = array
	}

	public init<T>(_ fixedArray: FixedArray<T>) {
		self.array = fixedArray.array as! Buffer
	}

	public init<S>(_ sequence: S) where Element == S.Element, S: Sequence {
		self.array = Array(sequence)
	}

	public init() {
		self.array = []
	}

	public func `as`<CastedType>(
		_ type: FixedArray<CastedType>.Type)
		-> FixedArray<CastedType>?
	{
		if let castedArray = self.array as? [CastedType] {
			return FixedArray<CastedType>(castedArray)
		}
		else {
			return nil
		}
	}

	// Expressible By Array Literal
	public typealias ArrayLiteralElement = Element

	public init(arrayLiteral elements: Element...) {
		self.array = elements
	}

	// ...
	public subscript (_ index: Int) -> Element {
		return array[index]
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

	public var isEmpty: Bool {
		return array.isEmpty
	}

	public var first: Element? {
		return array.first
	}

	public var last: Element? {
		return array.last
	}

	// Bidirectional Collection
	public func index(before i: Int) -> Int {
		return i - 1
	}

	//
	public func appending(_ newElement: Element) -> FixedArray<Element> {
		return FixedArray<Element>(self.array + [newElement])
	}

	public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> FixedArray<Element> {
		return try FixedArray(self.array.filter(isIncluded))
	}

	public func map<T>(_ transform: (Element) throws -> T) rethrows -> FixedArray<T> {
		return try FixedArray<T>(self.array.map(transform))
	}

	public func compactMap<T>(_ transform: (Element) throws -> T?) rethrows -> FixedArray<T> {
		return try FixedArray<T>(self.array.compactMap(transform))
	}

	public func flatMap<SegmentOfResult>(
		_ transform: (Element) throws -> SegmentOfResult)
		rethrows -> FixedArray<SegmentOfResult.Element>
		where SegmentOfResult: Sequence
	{
		return try FixedArray<SegmentOfResult.Element>(array.flatMap(transform))
	}

	@inlinable
	public func sorted(
		by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows
		-> FixedArray<Element>
	{
		return FixedArray(try array.sorted(by: areInIncreasingOrder))
	}

	public func appending<S>(contentsOf newElements: S) -> FixedArray<Element>
		where S: Sequence, Element == S.Element
	{
		return FixedArray<Element>(self.array + newElements)
	}

	public func reversed() -> [Element] {
		return array.reversed()
	}

	public var indices: Range<Int> {
		return array.indices
	}
}

extension FixedArray: Equatable where Element: Equatable { // kotlin: ignore
	public static func == (lhs: FixedArray, rhs: FixedArray) -> Bool {
		return lhs.array == rhs.array
	}

	//
	public func firstIndex(of element: Element) -> Int? {
		return array.firstIndex(of: element)
	}
}

extension FixedArray: Hashable where Element: Hashable { // kotlin: ignore
	public func hash(into hasher: inout Hasher) {
		array.hash(into: &hasher)
	}
}

extension FixedArray: Codable where Element: Codable { // kotlin: ignore
	public func encode(to encoder: Encoder) throws {
		try array.encode(to: encoder)
	}

	public init(from decoder: Decoder) throws {
		try self.init(Buffer(from: decoder))
	}
}

extension FixedArray where Element: Comparable { // kotlin: ignore
	@inlinable
	public func sorted() -> FixedArray<Element> {
		return FixedArray(array.sorted())
	}
}

// Array Class:

let array1: ArrayClass = [1, 2, 3]
let array2 = array1
array1[0] = 10
print(array1)
print(array2)
print(array2[0])

for i in array1 {
	print(i)
}

for j in array2 {
	print(j)
}

for i in array1 {
	for j in array2 {
		print("\(i), \(j)")
	}
}

// Fixed array:

let fixedArray1: FixedArray<Int> = [1, 2, 3]
print(fixedArray1[2] == 3)

let fixedArray2: FixedArray<Int> = []
print(fixedArray2.count == 0)

let fixedArray3: FixedArray<Any>? = fixedArray1.as(FixedArray<Any>.self)
let fixedArray4: FixedArray<Int>? = fixedArray3!.as(FixedArray<Int>.self)
print(fixedArray4![2] == 3)

for item in fixedArray1 {
	print(item)
}

print(fixedArray1.isEmpty)
print(fixedArray2.isEmpty)

print(fixedArray1.first! == 1)
print(fixedArray1.last! == 3)

print(fixedArray2.first == nil)
print(fixedArray2.last == nil)

let fixedArray5 = fixedArray1.filter { $0 > 2 }
print(fixedArray5.count == 1)
print(fixedArray5[0] == 3)

let fixedArray6 = fixedArray1.map { $0 + 1 }
print(fixedArray6.count == 3)
print(fixedArray6[2] == 4)

let fixedArray7 = fixedArray1.compactMap { ($0 > 2) ? $0 : nil }
print(fixedArray7.count == 1)
print(fixedArray7[0] == 3)

let fixedArray8 = fixedArray1.flatMap { (a: Int) -> FixedArray<Int> in [a, a + 1] }
print(fixedArray8.count == 6)
print(fixedArray8[0] == 1)
print(fixedArray8[5] == 4)

let fixedArray9: FixedArray<Int> = [3, 2, 1]
let fixedArray10 = fixedArray9.sorted()
print(fixedArray10[0] == 1)

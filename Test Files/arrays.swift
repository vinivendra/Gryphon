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

private func gryphonTemplates() {
	let _array1: MutableList<Any> = [1, 2, 3]
	let _array2: MutableList<Any> = [1, 2, 3]
	let _any: Any = 0
	let _string: String = ""
	let _index = _string.startIndex

	_ = zipToClass(_array1, _array2)
	_ = "_array1.zip(_array2)"

	_ = _string.suffix(from: _index)
	_ = "_string.suffix(startIndex = _index)"

	_ = _array1.toList()
	_ = "_array1.toList()"

	_ = _array1.appending(_any)
	_ = "_array1 + _any"

	_ = _array1.appending(contentsOf: _array2)
	_ = "_array1 + _array2"
}

/// According to http://swiftdoc.org/v4.2/type/Array/hierarchy/
/// (link found via https://www.raywenderlich.com/139591/building-custom-collection-swift)
/// the Array type in Swift conforms exactly to these protocols,
/// plus CustomReflectable (which is beyond Gryphon's scope for now).
public struct _ListSlice<Element>: Collection, // kotlin: ignore
	BidirectionalCollection,
	RandomAccessCollection,
	MutableCollection,
	RangeReplaceableCollection
{
	public typealias Index = Int
	public typealias SubSequence = _ListSlice<Element>

	let list: List<Element>
	let range: Range<Int>

	public var startIndex: Int {
		return range.startIndex
	}

	public var endIndex: Int {
		return range.endIndex
	}

	public subscript(position: Int) -> Element {
		get {
			return list[position]
		}

		// MutableCollection
		set {
			list._setElement(newValue, atIndex: position)
		}
	}

	public func index(after i: Int) -> Int {
        return list.index(after: i)
    }

	// BidirectionalCollection
	public func index(before i: Int) -> Int {
        return list.index(before: i)
    }

	// RangeReplaceableCollection
	public init() {
		self.list = []
		self.range = 0..<0
	}

	// Other methods
	public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> List<Element> {
		let array = list.array[range]
		return try List(array.filter(isIncluded))
	}

	public func map<T>(_ transform: (Element) throws -> T) rethrows -> List<T> {
		let array = list.array[range]
		return try List<T>(array.map(transform))
	}

	public func compactMap<T>(_ transform: (Element) throws -> T?) rethrows -> List<T> {
		let array = list.array[range]
		return try List<T>(array.compactMap(transform))
	}

	public func flatMap<SegmentOfResult>(
		_ transform: (Element) throws -> SegmentOfResult)
		rethrows -> List<SegmentOfResult.Element>
		where SegmentOfResult: Sequence
	{
		let array = list.array[range]
		return try List<SegmentOfResult.Element>(array.flatMap(transform))
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

public class List<Element>: CustomStringConvertible, // kotlin: ignore
	CustomDebugStringConvertible,
	ExpressibleByArrayLiteral,
	Sequence,
	Collection,
	BidirectionalCollection,
	RandomAccessCollection
{
	public typealias Buffer = [Element]
	public typealias ArrayLiteralElement = Element
	public typealias Index = Int
	public typealias SubSequence = _ListSlice<Element>

	public var array: Buffer

	public init(_ array: Buffer) {
		self.array = array
	}

	// Custom (Debug) String Convertible
	public var description: String {
		return array.description
	}

	public var debugDescription: String {
		return array.debugDescription
	}

	// Expressible By Array Literal
	public required init(arrayLiteral elements: Element...) {
		self.array = elements
	}

	// Sequence
	public func makeIterator() -> IndexingIterator<List<Element>> {
		return IndexingIterator(_elements: self)
	}

	// Collection
	public var startIndex: Int {
		return array.startIndex
	}

	public var endIndex: Int {
		return array.endIndex
	}

	public subscript(position: Int) -> Element {
		return array[position]
	}

	public func index(after i: Int) -> Int {
        return array.index(after: i)
    }

	// BidirectionalCollection
	public func index(before i: Int) -> Int {
        return array.index(before: i)
    }

	// Used for _ListSlice to conform to MutableCollection
	fileprivate func _setElement(_ element: Element, atIndex index: Int) {
		array[index] = element
	}

	// Other methods
	public init<T>(_ list: List<T>) {
		self.array = list.array as! Buffer
	}

	public init<S>(_ sequence: S) where Element == S.Element, S: Sequence {
		self.array = Array(sequence)
	}

	public init() {
		self.array = []
	}

	public func `as`<CastedType>(
		_ type: List<CastedType>.Type)
		-> List<CastedType>?
	{
		if let castedList = self.array as? [CastedType] {
			return List<CastedType>(castedList)
		}
		else {
			return nil
		}
	}

	public func toList() -> List<Element> {
		return List(array)
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

	public func dropFirst(_ k: Int = 1) -> List<Element> {
		return List(array.dropFirst())
	}

	public func dropLast(_ k: Int = 1) -> List<Element> {
		return List(array.dropLast())
	}

	public func appending(_ newElement: Element) -> List<Element> {
		return List<Element>(self.array + [newElement])
	}

	public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> List<Element> {
		return try List(self.array.filter(isIncluded))
	}

	public func map<T>(_ transform: (Element) throws -> T) rethrows -> List<T> {
		return try List<T>(self.array.map(transform))
	}

	public func compactMap<T>(_ transform: (Element) throws -> T?) rethrows -> List<T> {
		return try List<T>(self.array.compactMap(transform))
	}

	public func flatMap<SegmentOfResult>(
		_ transform: (Element) throws -> SegmentOfResult)
		rethrows -> List<SegmentOfResult.Element>
		where SegmentOfResult: Sequence
	{
		return try List<SegmentOfResult.Element>(array.flatMap(transform))
	}

	@inlinable
	public func sorted(
		by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows
		-> List<Element>
	{
		return List(try array.sorted(by: areInIncreasingOrder))
	}

	public func appending<S>(contentsOf newElements: S) -> List<Element>
		where S: Sequence, Element == S.Element
	{
		return List<Element>(self.array + newElements)
	}

	public func reversed() -> List<Element> {
		return List(array.reversed())
	}

	public var indices: Range<Int> {
		return array.indices
	}
}

extension List { // kotlin: ignore
	public func toMutableList() -> MutableList<Element> {
		return MutableList(array)
	}
}

// TODO: test
extension List { // kotlin: ignore
	@inlinable
	public static func + <Other>(
		lhs: List<Element>,
		rhs: Other)
		-> List<Element>
		where Other: Sequence,
		List.Element == Other.Element
	{
		var array = lhs.array
		for element in rhs {
			array.append(element)
		}
		return List(array)
	}
}

extension List: Equatable where Element: Equatable { // kotlin: ignore
	public static func == (lhs: List, rhs: List) -> Bool {
		return lhs.array == rhs.array
	}

	//
	public func firstIndex(of element: Element) -> Int? {
		return array.firstIndex(of: element)
	}
}

extension List: Hashable where Element: Hashable { // kotlin: ignore
	public func hash(into hasher: inout Hasher) {
		array.hash(into: &hasher)
	}
}

extension List where Element: Comparable { // kotlin: ignore
	@inlinable
	public func sorted() -> List<Element> {
		return List(array.sorted())
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

public class MutableList<Element>: List<Element>, // kotlin: ignore
	MutableCollection,
	RangeReplaceableCollection
{
	// MutableCollection
	public override subscript(position: Int) -> Element {
		get {
			return array[position]
		}
		set {
			array[position] = newValue
		}
	}

	// RangeReplaceableCollection
	override public required init() {
		super.init([])
	}

	public required init(arrayLiteral elements: Element...) {
		super.init(elements)
	}

	// Other methods
	override public init<T>(_ list: List<T>) {
		super.init(list.array as! Buffer)
	}

	public func `as`<CastedType>(
		_ type: MutableList<CastedType>.Type)
		-> MutableList<CastedType>?
	{
		if let castedList = self.array as? [CastedType] {
			return MutableList<CastedType>(castedList)
		}
		else {
			return nil
		}
	}

	public func append(_ newElement: Element) {
		array.append(newElement)
	}

	public func append<S>(contentsOf newElements: S) where S: Sequence, Element == S.Element {
		self.array.append(contentsOf: newElements)
	}

	public func insert(_ newElement: Element, at i: Index) {
		array.insert(newElement, at: i)
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
		self.array = self.array.reversed()
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

public protocol BackedByArray { // kotlin: ignore
	associatedtype Element
	var arrayBacking: [Element] { get }
}

extension List: BackedByArray { // kotlin: ignore
	public var arrayBacking: [Element] {
		return self.array
	}
}

extension Array: BackedByArray { // kotlin: ignore
	public var arrayBacking: [Element] {
		return self
	}
}

public func zipToClass<Array1, Element1, Array2, Element2>( // kotlin: ignore
	_ array1: Array1,
	_ array2: Array2)
	-> List<(Element1, Element2)>
	where Array1: BackedByArray,
	Array2: BackedByArray,
	Element1 == Array1.Element,
	Element2 == Array2.Element
{
	return List(Array(zip(array1.arrayBacking, array2.arrayBacking)))
}


////////////////////////////////////////////////////////////////////////////////////////////////////
// Mutable List

let mutableList1: MutableList = [1, 2, 3]
let mutableList2 = mutableList1
mutableList1[0] = 10
print(mutableList1)
print(mutableList2)
print(mutableList2[0])

for i in mutableList1 {
	print(i)
}

for j in mutableList2 {
	print(j)
}

for i in mutableList1 {
	for j in mutableList2 {
		print("\(i), \(j)")
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// List

let list1: List<Int> = [1, 2, 3]
print(list1[2] == 3)

let list2: List<Int> = []
print(list2.count == 0)

let list3: List<Any>? = list1.as(List<Any>.self)
let list4: List<Int>? = list3!.as(List<Int>.self)
print(list4![2] == 3)

for item in list1 {
	print(item)
}

print(list1.isEmpty)
print(list2.isEmpty)

print(list1.first! == 1)
print(list1.last! == 3)

print(list2.first == nil)
print(list2.last == nil)

let list5 = list1.filter { $0 > 2 }
print(list5.count == 1)
print(list5[0] == 3)

let list6 = list1.map { $0 + 1 }
print(list6.count == 3)
print(list6[2] == 4)

let list7 = list1.compactMap { ($0 > 2) ? $0 : nil }
print(list7.count == 1)
print(list7[0] == 3)

let list8 = list1.flatMap { (a: Int) -> List<Int> in [a, a + 1] }
print(list8.count == 6)
print(list8[0] == 1)
print(list8[5] == 4)

let list9: List<Int> = [3, 2, 1]
let list10 = list9.sorted()
print(list10[0] == 1)

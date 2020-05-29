//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
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

// gryphon output: Sources/GryphonLib/AuxiliaryFileContents.swiftAST
// gryphon output: Sources/GryphonLib/AuxiliaryFileContents.gryphonASTRaw
// gryphon output: Sources/GryphonLib/AuxiliaryFileContents.gryphonAST
// gryphon output: Bootstrap/AuxiliaryFileContents.kt

let dollarSign = "$" // gryphon value: "\\$"
let kotlinStringInterpolation = "{_string}"

// gryphon multiline
internal let gryphonKotlinLibraryFileContents = """
// Replace this with the real package identifier:
package /* com.example.myApp */

//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
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

import java.lang.ClassCastException

fun String.suffix(startIndex: Int): String {
    return this.substring(startIndex, this.length)
}

fun <T> MutableList<T>.removeLast() {
    this.removeAt(this.size - 1)
}

fun String.indexOrNull(character: Char): Int? {
    val result = this.indexOf(character)
    if (result == -1) {
        return null
    }
    else {
        return result
    }
}

@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified T> List<*>.castOrNull(): List<T>? {
    if (this.all { it is T }) {
        return this as List<T>
    }
    else {
        return null
    }
}

@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified T> List<*>.castMutableOrNull(): MutableList<T>? {
    if (this.all { it is T }) {
        return (this as List<T>).toMutableList()
    }
    else {
        return null
    }
}

@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified K, reified V> Map<*, *>.castOrNull()
    : Map<K, V>?
{
    if (this.all { it.key is K && it.value is V }) {
        return this as Map<K, V>
    }
    else {
        return null
    }
}

@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified K, reified V> Map<*, *>.castMutableOrNull()
    : MutableMap<K, V>?
{
    if (this.all { it.key is K && it.value is V }) {
        return (this as Map<K, V>).toMutableMap()
    }
    else {
        return null
    }
}


@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified T> List<*>.cast(): List<T> {
    if (this.all { it is T }) {
        return this as List<T>
    }
    else {
        throw ClassCastException()
    }
}

@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified T> List<*>.castMutable(): MutableList<T> {
    if (this.all { it is T }) {
        return (this as List<T>).toMutableList()
    }
    else {
        throw ClassCastException()
    }
}

@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified K, reified V> Map<*, *>.cast()
    : Map<K, V>
{
    if (this.all { it.key is K && it.value is V }) {
        return this as Map<K, V>
    }
    else {
        throw ClassCastException()
    }
}

@Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
inline fun <reified K, reified V> Map<*, *>.castMutable()
    : MutableMap<K, V>
{
    if (this.all { it.key is K && it.value is V }) {
        return (this as Map<K, V>).toMutableMap()
    }
    else {
        throw ClassCastException()
    }
}

fun <Element> List<Element>.sorted(
    isAscending: (Element, Element) -> Boolean)
    : MutableList<Element>
{
    val copyList = this.toMutableList()
    copyList.quicksort(0, this.size - 1, isAscending)
    return copyList
}

fun <Element> MutableList<Element>.quicksort(
    left: Int,
    right: Int,
    isAscending: (Element, Element) -> Boolean)
{
    if (left < right) {
        val pivot = this.partition(left, right, isAscending)
        this.quicksort(left, pivot - 1, isAscending)
        this.quicksort(pivot + 1, right, isAscending)
    }
}

fun <Element> MutableList<Element>.partition(
    left: Int,
    right: Int,
    isAscending: (Element, Element) -> Boolean)
    : Int
{
    val pivot = this[right]

    var i = left - 1

    var j = left
    while (j <= right - 1) {
        if (isAscending(this[j], pivot)) {
            i += 1

            val aux = this[i]
            this[i] = this[j]
            this[j] = aux
        }

        j += 1
    }

    val aux = this[i + 1]
    this[i + 1] = this[right]
    this[right] = aux

    return i + 1
}

"""

// gryphon multiline
internal let gryphonSwiftLibraryFileContents = """
//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
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

// Replacement for Comparable
private struct _Comparable: Comparable { // gryphon ignore
	static func < (lhs: _Comparable, rhs: _Comparable) -> Bool {
		return false
	}
}

private func gryphonTemplates() {
	let _array1: MutableList<Any> = [1, 2, 3]
	let _array2: MutableList<Any> = [1, 2, 3]
	let _any: Any = 0
	let _string: String = ""
	let _index = _string.startIndex
	let _comparableArray: List<_Comparable> = []
	let _closure: (_Comparable, _Comparable) -> Bool = { _, _ in true }

	// Templates with an input that references methods defined in this file
	_ = zip(_array1, _array2)
	_ = "_array1.zip(_array2)"

	_ = _array1.toList()
	_ = "_array1.toList()"

	_ = _array1.appending(_any)
	_ = "_array1 + _any"

	_ = _array1.appending(contentsOf: _array2)
	_ = "_array1 + _array2"

	// Templates with an output that references methods defined in the GryphonKotlinLibrary.kt file
	_ = _string.suffix(from: _index)
	_ = "_string.suffix(startIndex = _index)"

	_ = _comparableArray.sorted(by: _closure)
	_ = "_comparableArray.sorted(isAscending = _closure)"

	_ = _array1.removeLast()
	_ = "_array1.removeLast()"
}

////////////////////////////////////////////////////////////////////////////////////////////////////

/// According to http://swiftdoc.org/v4.2/type/Array/hierarchy/
/// (link found via https://www.raywenderlich.com/139591/building-custom-collection-swift)
/// the Array type in Swift conforms exactly to these protocols,
/// plus CustomReflectable (which is beyond Gryphon's scope for now).
public struct _ListSlice<Element>: Collection, // gryphon ignore
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

public class List<Element>: CustomStringConvertible, // gryphon ignore
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
	public init<S>(_ sequence: S) where Element == S.Element, S: Sequence {
		self.array = Array(sequence)
	}

	public init() {
		self.array = []
	}

	/// Used to obtain a List with a new element type. If all elements in the list can be casted to
	/// the new type, the method succeeds and the new MutableList is returned. Otherwise, the method
	/// returns `nil`.
	public func `as`<CastedType>(_ type: List<CastedType>.Type) -> List<CastedType>? {
		if let castedList = self.array as? [CastedType] {
			return List<CastedType>(castedList)
		}
		else {
			return nil
		}
	}

	/// Used to obtain a List with a new element type. If all elements in the list can be casted to
	/// the new type, the method succeeds and the new MutableList is returned. Otherwise, the method
	/// crashes.
	public func forceCast<CastedType>(to type: List<CastedType>.Type) -> List<CastedType> {
		List<CastedType>(array as! [CastedType])
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

	public func prefix(while predicate: (Element) throws -> Bool) rethrows -> List<Element> {
		return try List<Element>(array.prefix(while: predicate))
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

////////////////////////////////////////////////////////////////////////////////////////////////////

extension List { // gryphon ignore
	public func toMutableList() -> MutableList<Element> {
		return MutableList(array)
	}
}

extension List { // gryphon ignore
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

extension List: Equatable where Element: Equatable { // gryphon ignore
	public static func == (lhs: List, rhs: List) -> Bool {
		return lhs.array == rhs.array
	}

	//
	public func firstIndex(of element: Element) -> Int? {
		return array.firstIndex(of: element)
	}
}

extension List: Hashable where Element: Hashable { // gryphon ignore
	public func hash(into hasher: inout Hasher) {
		array.hash(into: &hasher)
	}
}

extension List where Element: Comparable { // gryphon ignore
	@inlinable
	public func sorted() -> List<Element> {
		return List(array.sorted())
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

public class MutableList<Element>: List<Element>, // gryphon ignore
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
extension List { // gryphon ignore

	/// Used to obtain a MutableList with a new element type. If all elements in the list can be
	/// casted to the new type, the method succeeds and the new MutableList is returned. Otherwise,
	/// the method returns `nil`.
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

	/// Used to obtain a MutableList with a new element type. If all elements in the list can be
	/// casted to the new type, the method succeeds and the new MutableList is returned. Otherwise,
	/// the method crashes.
	public func forceCast<CastedType>(
		to type: MutableList<CastedType>.Type)
		-> MutableList<CastedType>
	{
		MutableList<CastedType>(array as! [CastedType])
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

public func zip<ASequence, ListElement>( // gryphon ignore
	_ array1: ASequence,
	_ array2: List<ListElement>)
	-> List<(ASequence.Element, ListElement)>
	where ASequence: Sequence
{
	return List(Swift.zip(array1, array2))
}

public func zip<ASequence, ListElement>( // gryphon ignore
	_ array1: List<ListElement>,
	_ array2: ASequence)
	-> List<(ListElement, ASequence.Element)>
	where ASequence: Sequence
{
	return List(Swift.zip(array1, array2))
}

public func zip<List1Element, List2Element>( // gryphon ignore
	_ array1: List<List1Element>,
	_ array2: List<List2Element>)
	-> List<(List1Element, List2Element)>
{
	return List(Swift.zip(array1, array2))
}

////////////////////////////////////////////////////////////////////////////////////////////////////

/// According to https://swiftdoc.org/v4.2/type/dictionary/hierarchy/
/// the Dictionary type in Swift conforms exactly to these protocols,
/// plus CustomReflectable (which is beyond Gryphon's scope for now).
public class Map<Key, Value>: // gryphon ignore
	CustomStringConvertible,
	CustomDebugStringConvertible,
	ExpressibleByDictionaryLiteral,
	Collection
	where Key: Hashable
{
	public typealias Buffer = [Key: Value]
	public typealias KeyValueTuple = (key: Key, value: Value)

	public typealias SubSequence = Slice<Buffer>
	public typealias Index = Buffer.Index
	public typealias Element = KeyValueTuple

	public var dictionary: Buffer

	public init(_ dictionary: Buffer) {
		self.dictionary = dictionary
	}

	// The tuple inside the list has to be translated as a Pair for Kotlin compatibility
	public func toList() -> List<(Key, Value)> {
		return List(dictionary).map { (\(dollarSign)0.0, \(dollarSign)0.1) }
	}

	// Custom (Debug) String Convertible
	public var description: String {
		return dictionary.description
	}

	public var debugDescription: String {
		return dictionary.debugDescription
	}

	// Expressible By Dictionary Literal
	public required init(dictionaryLiteral elements: (Key, Value)...) {
		self.dictionary = Buffer(uniqueKeysWithValues: elements)
	}

	// Sequence
	public func makeIterator() -> IndexingIterator<Map<Key, Value>> {
		return IndexingIterator(_elements: self)
	}

	// Collection
	public var startIndex: Index {
		return dictionary.startIndex
	}

	public var endIndex: Index {
		return dictionary.endIndex
	}

	@inlinable
	public subscript(position: Index) -> Element {
		return dictionary[position]
	}

	public func index(after i: Index) -> Index {
		return dictionary.index(after: i)
	}

	// Other methods

	/// Used to obtain a Map with new key and/or value types. If all keys and values in the map can
	/// be casted to the new types, the method succeeds and the new Map is returned. Otherwise, the
	/// method returns `nil`.
	public func `as`<CastedKey, CastedValue>(
		_ type: Map<CastedKey, CastedValue>.Type)
		-> Map<CastedKey, CastedValue>?
	{
		if let castedDictionary = self.dictionary as? [CastedKey: CastedValue] {
			return Map<CastedKey, CastedValue>(castedDictionary)
		}
		else {
			return nil
		}
	}

	/// Used to obtain a Map with new key and/or value types. If all keys and values in the map can
	/// be casted to the new types, the method succeeds and the new Map is returned. Otherwise, the
	/// method crashes.
	public func forceCast<CastedKey, CastedValue>(
		to type: Map<CastedKey, CastedValue>.Type)
		-> Map<CastedKey, CastedValue>
	{
		Map<CastedKey, CastedValue>(dictionary as! [CastedKey: CastedValue])
	}

	public func toMap() -> Map<Key, Value> {
		return Map(dictionary)
	}

	public subscript (_ key: Key) -> Value? {
		return dictionary[key]
	}

	@inlinable
	public func formIndex(after i: inout Index) {
		dictionary.formIndex(after: &i)
	}

	@inlinable
	public func index(forKey key: Key) -> Index? {
		return dictionary.index(forKey: key)
	}

	@inlinable public var count: Int {
		return dictionary.count
	}

	@inlinable public var isEmpty: Bool {
		return dictionary.isEmpty
	}

	public func map<T>(_ transform: (KeyValueTuple) throws -> T)
		rethrows -> List<T>
	{
		return try List<T>(self.dictionary.map(transform))
	}

	@inlinable
	public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> Map<Key, T> {
		return try Map<Key, T>(dictionary.mapValues(transform))
	}

	@inlinable
	public func sorted(
		by areInIncreasingOrder: (KeyValueTuple, KeyValueTuple) throws -> Bool)
		rethrows -> MutableList<KeyValueTuple>
	{
		return MutableList<KeyValueTuple>(try dictionary.sorted(by: areInIncreasingOrder))
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

extension Map { // gryphon ignore
	public func toMutableMap() -> MutableMap<Key, Value> {
		return MutableMap(dictionary)
	}
}

extension Map: Equatable where Value: Equatable { // gryphon ignore
	public static func == (lhs: Map, rhs: Map) -> Bool {
		return lhs.dictionary == rhs.dictionary
	}
}

extension Map: Hashable where Value: Hashable { // gryphon ignore
	public func hash(into hasher: inout Hasher) {
		dictionary.hash(into: &hasher)
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

public class MutableMap<Key, Value>: Map<Key, Value> where Key: Hashable { // gryphon ignore
	override public subscript (_ key: Key) -> Value? {
		get {
			return dictionary[key]
		}
		set {
			dictionary[key] = newValue
		}
	}
}

extension Map { // gryphon ignore
	/// Used to obtain a MutableMap with new key and/or value types. If all keys and values in the
	/// map can be casted to the new types, the method succeeds and the new MutableMap is returned.
	/// Otherwise, the method returns `nil`.
	public func `as`<CastedKey, CastedValue>(
		_ type: MutableMap<CastedKey, CastedValue>.Type)
		-> MutableMap<CastedKey, CastedValue>?
	{
		if let castedDictionary = self.dictionary as? [CastedKey: CastedValue] {
			return MutableMap<CastedKey, CastedValue>(castedDictionary)
		}
		else {
			return nil
		}
	}

	/// Used to obtain a Map with new key and/or value types. If all keys and values in the map can
	/// be casted to the new types, the method succeeds and the new Map is returned. Otherwise, the
	/// method crashes.
	public func forceCast<CastedKey, CastedValue>(
		to type: MutableMap<CastedKey, CastedValue>.Type)
		-> MutableMap<CastedKey, CastedValue>
	{
		MutableMap<CastedKey, CastedValue>(dictionary as! [CastedKey: CastedValue])
	}
}

"""

// gryphon multiline
internal let gryphonXCTestFileContents = """
// Replacement for Comparable
private struct _Comparable: Comparable {
	static func < (lhs: _Comparable, rhs: _Comparable) -> Bool {
		return false
	}
}

// Replacement for Optional
private struct _Optional { }

class XCTestCase { // gryphon ignore
	class func setUp() { }
	class func tearDown() { }

	public func XCTAssert(_ condition: Bool, _ message: String = "") { }
	public func XCTAssertEqual<T>(_ a: T, _ b: T, _ message: String = "") where T : Equatable { }
	public func XCTAssertNotEqual<T>(_ a: T, _ b: T, _ message: String = "") where T : Equatable { }
	public func XCTAssertFalse(_ condition: Bool, _ message: String = "") { }
	public func XCTAssertNil<T>(_ expression: T?, _ message: String = "") { }
	public func XCTAssertNotNil<T>(_ expression: T?, _ message: String = "") { }
	public func XCTAssertNoThrow<T>(
		_ expression: @autoclosure () throws -> T,
		_ message: String = "") { }
	public func XCTAssertThrowsError<T>(
		_ expression: @autoclosure () throws -> T,
		_ message: String = "") { }
	public func XCTFail(_ message: String = "") { }
}

extension XCTestCase {
	private func gryphonTemplates() {
		let _bool = true
		let _string = ""
		let _any1: _Comparable = _Comparable()
		let _any2: _Comparable = _Comparable()
		let _optional: _Optional? = _Optional()

		XCTAssert(_bool)
		_ = "XCTAssert(_bool)"

		XCTAssert(_bool, _string)
		_ = "XCTAssert(_bool, _string)"

		XCTAssertFalse(_bool)
		_ = "XCTAssertFalse(_bool)"

		XCTAssertFalse(_bool, _string)
		_ = "XCTAssertFalse(_bool, _string)"

		XCTAssertNil(_optional)
		_ = "XCTAssertNil(_optional)"

		XCTAssertNil(_optional, _string)
		_ = "XCTAssertNil(_optional, _string)"

		XCTAssertEqual(_any1, _any2, _string)
		_ = "XCTAssertEqual(_any1, _any2, _string)"

		XCTAssertEqual(_any1, _any2)
		_ = "XCTAssertEqual(_any1, _any2)"
	}
}

"""

// gryphon multiline
internal let gryphonTemplatesLibraryFileContents = """
// WARNING: Any changes to this file should be reflected in the literal string in
// AuxiliaryFileContents.swift

import Foundation

// MARK: - Define special types as stand-ins for some protocols and other types

// Replacement for Hashable
private struct _Hashable: Hashable { }

// Replacement for Comparable
private struct _Comparable: Comparable {
	static func < (lhs: _Comparable, rhs: _Comparable) -> Bool {
		return false
	}
}

// Replacement for Optional
private struct _Optional { }

// Replacement for Any
private struct _Any: CustomStringConvertible, LosslessStringConvertible {
	init() { }

	var description: String = ""

	init?(_ description: String) {
		return nil
	}
}

// MARK: - Define the templates
private func gryphonTemplates() {

	// MARK: Declare placeholder variables to use in the templates
	var _bool: Bool = true
	var _strArray: [String] = []
	var _array: [Any] = []
	var _array1: [Any] = []
	var _array2: [Any] = []
	let _array3: [Any] = []
	var _arrayOfOptionals: [Any?] = []
	var _comparableArray: [_Comparable] = []
	let _comparable = _Comparable()
	var _index: String.Index = "abc".endIndex
	let _index1: String.Index = "abc".startIndex
	let _index2: String.Index = "abc".startIndex
	var _string: String = "abc"
	var _string1: String = "abc"
	let _string2: String = "abc"
	let _string3: String = "abc"
	let _character: Character = "a"
	let _substring: Substring = "abc".dropLast()
	let _range: Range<String.Index> = _string.startIndex..<_string.endIndex
	let _any: Any = "abc"
	let _anyType: _Any = _Any()
	let _optional: _Optional? = _Optional()
	let _double: Double = 0
	let _double1: Double = 0
	let _double2: Double = 0
	let _int: Int = 0
	let _int1: Int = 0
	let _int2: Int = 0
	let _dictionary: [_Hashable: Any] = [:]
	let _closure: (Any, Any) -> Any = { a, b in a }
	let _closure2: (Any) -> Any = { a in a }
	let _closure3: (Any) -> Bool = { _ in true }
	let _closure4: (_Optional) -> Any = { _ in true }
	let _closure5: (Character) -> Bool = { _ in true }
	let _closure6: (Any) -> Any? = { a in a }
	let _closure7: (_Comparable, _Comparable) -> Bool = { _, _ in true }

	// MARK: Declare the templates

	// System
	_ = print(_any)
	_ = "println(_any)"

	_ = print(_any, terminator: "")
	_ = "print(_any)"

	_ = fatalError(_string)
	_ = "println(\\\"Fatal error: \(dollarSign)\(kotlinStringInterpolation)\\\"); exitProcess(-1)"

	_ = assert(_bool)
	_ = "assert(_bool)"

	// Darwin
	_ = sqrt(_double)
	_ = "Math.sqrt(_double)"

	// String
	_ = String(_anyType)
	_ = "_anyType.toString()"

	_ = _anyType.description
	_ = "_anyType.toString()"

	_ = _string.isEmpty
	_ = "_string.isEmpty()"

	_ = _string.count
	_ = "_string.length"

	_ = _string.first
	_ = "_string.firstOrNull()"

	_ = _string.last
	_ = "_string.lastOrNull()"

	_ = Double(_string)
	_ = "_string.toDouble()"

	_ = Float(_string)
	_ = "_string.toFloat()"

	_ = UInt64(_string)
	_ = "_string.toULong()"

	_ = Int64(_string)
	_ = "_string.toLong()"

	_ = Int(_string)
	_ = "_string.toIntOrNull()"

	_ = _string.dropLast()
	_ = "_string.dropLast(1)"

	_ = _string.dropLast(_int)
	_ = "_string.dropLast(_int)"

	_ = _string.dropFirst()
	_ = "_string.drop(1)"

	_ = _string.dropFirst(_int)
	_ = "_string.drop(_int)"

	_ = _string.drop(while: _closure5)
	_ = "_string.dropWhile _closure5"

	_ = _string.indices
	_ = "_string.indices"

	_ = _string.firstIndex(of: _character)!
	_ = "_string.indexOf(_character)"

	_ = _string.contains(where: _closure5)
	_ = "(_string.find _closure5 != null)"

	_ = _string.firstIndex(of: _character)
	_ = "_string.indexOrNull(_character)"

	_ = _string.prefix(_int)
	_ = "_string.substring(0, _int)"

	_ = _string.prefix(upTo: _index)
	_ = "_string.substring(0, _index)"

	_ = _string[_index...]
	_ = "_string.substring(_index)"

	_ = _string[..<_index]
	_ = "_string.substring(0, _index)"

	_ = _string[..._index]
	_ = "_string.substring(0, _index + 1)"

	_ = _string[_index1..<_index2]
	_ = "_string.substring(_index1, _index2)"

	_ = _string[_index1..._index2]
	_ = "_string.substring(_index1, _index2 + 1)"

	_ = String(_substring)
	_ = "_substring"

	_ = _string.endIndex
	_ = "_string.length"

	_ = _string.startIndex
	_ = "0"

	_ = _string.formIndex(before: &_index)
	_ = "_index -= 1"

	_ = _string.index(after: _index)
	_ = "_index + 1"

	_ = _string.index(before: _index)
	_ = "_index - 1"

	_ = _string.index(_index, offsetBy: _int)
	_ = "_index + _int"

	_ = _substring.index(_index, offsetBy: _int)
	_ = "_index + _int"

	_ = _string1.replacingOccurrences(of: _string2, with: _string3)
	_ = "_string1.replace(_string2, _string3)"

	_ = _string1.prefix(while: _closure5)
	_ = "_string1.takeWhile _closure5"

	_ = _string1.hasPrefix(_string2)
	_ = "_string1.startsWith(_string2)"

	_ = _string1.hasSuffix(_string2)
	_ = "_string1.endsWith(_string2)"

	_ = _range.lowerBound
	_ = "_range.start"

	_ = _range.upperBound
	_ = "_range.endInclusive"

	_ = Range<String.Index>(uncheckedBounds: (lower: _index1, upper: _index2))
	_ = "IntRange(_index1, _index2)"

	_ = _string1.append(_string2)
	_ = "_string1 += _string2"

	_ = _string.append(_character)
	_ = "_string += _character"

	_ = _string.capitalized
	_ = "_string.capitalize()"

	_ = _string.uppercased()
	_ = "_string.toUpperCase()"

	// Character
	_ = _character.uppercased()
	_ = "_character.toUpperCase()"

	// Array
	_ = _array.append(_any)
	_ = "_array.add(_any)"

	_ = _array.insert(_any, at: _int)
	_ = "_array.add(_int, _any)"

	_ = _arrayOfOptionals.append(nil)
	_ = "_arrayOfOptionals.add(null)"

	_ = _array1.append(contentsOf: _array2)
	_ = "_array1.addAll(_array2)"

	_ = _array1.append(contentsOf: _array3)
	_ = "_array1.addAll(_array3)"

	_ = _array.isEmpty
	_ = "_array.isEmpty()"

	_ = _strArray.joined(separator: _string)
	_ = "_strArray.joinToString(separator = _string)"

	_ = _strArray.joined()
	_ = "_strArray.joinToString(separator = \\\"\\\")"

	_ = _array.count
	_ = "_array.size"

	_ = _array.indices
	_ = "_array.indices"

	_ = _array.startIndex
	_ = "0"

	_ = _array.endIndex
	_ = "_array.size"

	_ = _array.index(after: _int)
	_ = "_int + 1"

	_ = _array.index(before: _int)
	_ = "_int - 1"

	_ = _array.first
	_ = "_array.firstOrNull()"

	_ = _array.first(where: _closure3)
	_ = "_array.find _closure3"

	_ = _array.last(where: _closure3)
	_ = "_array.findLast _closure3"

	_ = _array.last
	_ = "_array.lastOrNull()"

	_ = _array.prefix(while: _closure3)
	_ = "_array.takeWhile _closure3"

	_ = _array.removeFirst()
	_ = "_array.removeAt(0)"

	_ = _array.remove(at: _int)
	_ = "_array.removeAt(_int)"

	_ = _array.dropFirst()
	_ = "_array.drop(1)"

	_ = _array.dropLast()
	_ = "_array.dropLast(1)"

	_ = _array.map(_closure2)
	_ = "_array.map _closure2"

	_ = _array.flatMap(_closure6)
	_ = "_array.flatMap _closure6"

	_ = _array.compactMap(_closure2)
	_ = "_array.map _closure2.filterNotNull()"

	_ = _array.filter(_closure3)
	_ = "_array.filter _closure3"

	_ = _array.reduce(_any, _closure)
	_ = "_array.fold(_any) _closure"

	_ = zip(_array1, _array2)
	_ = "_array1.zip(_array2)"

	_ = _array.firstIndex(where: _closure3)
	_ = "_array.indexOfFirst _closure3"

	_ = _array.contains(where: _closure3)
	_ = "(_array.find _closure3 != null)"

	_ = _comparableArray.sorted()
	_ = "_comparableArray.sorted()"

	_ = _comparableArray.contains(_comparable)
	_ = "_comparableArray.contains(_comparable)"

	_ = _comparableArray.firstIndex(of: _comparable)
	_ = "_comparableArray.indexOf(_comparable)"

	// Dictionary
	_ = _dictionary.count
	_ = "_dictionary.size"

	_ = _dictionary.isEmpty
	_ = "_dictionary.isEmpty()"

	_ = _dictionary.map(_closure2)
	_ = "_dictionary.map _closure2"

	// Int
	_ = Int.max
	_ = "Int.MAX_VALUE"

	_ = Int.min
	_ = "Int.MIN_VALUE"

	_ = min(_int1, _int2)
	_ = "Math.min(_int1, _int2)"

	_ = _int1..._int2
	_ = "_int1.._int2"

	_ = _int1..<_int2
	_ = "_int1 until _int2"

	// Double
	_ = _double1..._double2
	_ = "(_double1).rangeTo(_double2)"

	// Optional
	_ = _optional.map(_closure4)
	_ = "_optional?.let _closure4"
}

"""

// gryphon multiline
internal let mapKotlinErrorsToSwiftFileContents = """
// WARNING: Any changes to this file should be reflected in the literal string in
// AuxiliaryFileContents.swift

// Examples of compatible errors:
//
//main.kt:2:5: error: conflicting declarations: var result: String, var result: String
//var result: String = ""
//    ^
//main.kt:3:5: error: conflicting declarations: var result: String, var result: String
//var result = result
//    ^

import Foundation

func getAbsoultePath(forFile file: String) -> String {
	return "/" + URL(fileURLWithPath: file).pathComponents.dropFirst().joined(separator: "/")
}

struct ErrorInformation {
	let filePath: String
	let lineNumber: Int
	let columnNumber: Int
	let errorMessage: String
}

func getInformation(fromString string: String) -> ErrorInformation {
	let components = string.split(separator: ":")
	return ErrorInformation(
		filePath: String(components[0]),
		lineNumber: Int(components[1])!,
		columnNumber: Int(components[2])!,
		errorMessage: String(components[3...].joined(separator: ":")))
}

struct SourceFileRange {
	let lineStart: Int
	let columnStart: Int
	let lineEnd: Int
	let columnEnd: Int
}

struct Mapping {
	let kotlinRange: SourceFileRange
	let swiftRange: SourceFileRange
}

struct ErrorMap {
	let kotlinFilePath: String
	let swiftFilePath: String
	let mappings: [Mapping]

	init(kotlinFilePath: String, contents: String) {
		self.kotlinFilePath = kotlinFilePath

		let components = contents.split(separator: "\\n")
		self.swiftFilePath = String(components[0])

		self.mappings = components.dropFirst().map { string in
			let mappingComponents = string.split(separator: ":")
			let kotlinRange = SourceFileRange(
				lineStart: Int(mappingComponents[0])!,
				columnStart: Int(mappingComponents[1])!,
				lineEnd: Int(mappingComponents[2])!,
				columnEnd: Int(mappingComponents[3])!)
			let swiftRange = SourceFileRange(
				lineStart: Int(mappingComponents[4])!,
				columnStart: Int(mappingComponents[5])!,
				lineEnd: Int(mappingComponents[6])!,
				columnEnd: Int(mappingComponents[7])!)
			return Mapping(kotlinRange: kotlinRange, swiftRange: swiftRange)
		}
	}

	func getSwiftRange(forKotlinLine line: Int, column: Int) -> SourceFileRange? {
		for mapping in mappings {
			if compare(
					line1: mapping.kotlinRange.lineStart,
					column1: mapping.kotlinRange.columnStart,
					isBeforeLine2: line,
					column2: column),
				compare(
					line1: line,
					column1: column,
					isBeforeLine2: mapping.kotlinRange.lineEnd,
					column2: mapping.kotlinRange.columnEnd)
			{
				return mapping.swiftRange
			}
		}

		return nil
	}

	func compare(line1: Int, column1: Int, isBeforeLine2 line2: Int, column2: Int) -> Bool {
		if line1 < line2 {
			return true
		}
		else if line1 == line2 {
			if column1 <= column2 {
				return true
			}
		}

		return false
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
var input: [String] = []

// Read all the input, separated into lines
while let nextLine = readLine(strippingNewline: false) {
	input.append(nextLine)
}

// Join the lines into errors/warnings
var errors: [String] = []
var currentError = ""
for line in input {
	if line.contains(": error: ") || line.contains(": warning: ") {
		if !currentError.isEmpty {
			errors.append(currentError)
		}
		currentError = line
	}
	else {
		currentError += line
	}
}
if !currentError.isEmpty {
	errors.append(currentError)
}

// Handle the errors
var errorMaps: [String: ErrorMap] = [:]
for error in errors {
	let errorInformation = getInformation(fromString: error)
	let errorMapPath =
		"\(SupportingFile.kotlinErrorMapsFolder)/" + errorInformation.filePath.dropLast(2) +
		"kotlinErrorMap"

	if errorMaps[errorMapPath] == nil {
		if let fileContents = try? String(contentsOfFile: errorMapPath) {
			errorMaps[errorMapPath] = ErrorMap(
				kotlinFilePath: errorInformation.filePath,
				contents: fileContents)
		}
		else {
			print(error)
			continue
		}
	}

	let errorMap = errorMaps[errorMapPath]!

	if let swiftRange = errorMap.getSwiftRange(
		forKotlinLine: errorInformation.lineNumber,
		column: errorInformation.columnNumber)
	{
		print("\\(getAbsoultePath(forFile: errorMap.swiftFilePath)):\\(swiftRange.lineStart):" +
			"\\(swiftRange.columnStart):\\(errorInformation.errorMessage)")
	}
	else {
		print(error)
	}
}

"""

// gryphon multiline
internal let mapGradleErrorsToSwiftFileContents = """
// WARNING: Any changes to this file should be reflected in the literal string in
// AuxiliaryFileContents.swift

// This script should be run on a folder initialized by Gryphon (i.e. containing the relevant
// `\(SupportingFile.gryphonBuildFolder)` folder)

// Examples of compatible errors:
//e: /path/to/Model.kt: (15, 2): Expecting member declaration
//e: /path/to/Model.kt: (12, 44): Unresolved reference: foo

import Foundation

func getAbsoultePath(forFile file: String) -> String {
	return "/" + URL(fileURLWithPath: file).pathComponents.dropFirst().joined(separator: "/")
}

func getRelativePath(forFile file: String) -> String {
	let currentDirectoryPath = FileManager.default.currentDirectoryPath
	let absoluteFilePath = getAbsoultePath(forFile: file)
	return String(absoluteFilePath.dropFirst(currentDirectoryPath.count + 1))
}

struct ErrorInformation {
	let filePath: String
	let lineNumber: Int
	let columnNumber: Int
	let errorMessage: String
	let isError: Bool
}

func getInformation(fromString string: String) -> ErrorInformation {
	let components = string.split(separator: ":")
	let filePath = String(components[1].dropFirst()) // Drop the first space
	let lineAndColumn = components[2].dropFirst(2).dropLast().split(separator: ",")
	let line = Int(lineAndColumn[0])!
	let column = Int(lineAndColumn[1].dropFirst())!
	return ErrorInformation(
		filePath: getRelativePath(forFile: filePath),
		lineNumber: line,
		columnNumber: column,
		errorMessage: String(components[3...].joined(separator: ":")),
		isError: components[0] == "e")
}

struct SourceFileRange {
	let lineStart: Int
	let columnStart: Int
	let lineEnd: Int
	let columnEnd: Int
}

struct Mapping {
	let kotlinRange: SourceFileRange
	let swiftRange: SourceFileRange
}

struct ErrorMap {
	let kotlinFilePath: String
	let swiftFilePath: String
	let mappings: [Mapping]

	init(kotlinFilePath: String, contents: String) {
		self.kotlinFilePath = kotlinFilePath

		let components = contents.split(separator: "\\n")
		self.swiftFilePath = String(components[0])

		self.mappings = components.dropFirst().map { string in
			let mappingComponents = string.split(separator: ":")
			let kotlinRange = SourceFileRange(
				lineStart: Int(mappingComponents[0])!,
				columnStart: Int(mappingComponents[1])!,
				lineEnd: Int(mappingComponents[2])!,
				columnEnd: Int(mappingComponents[3])!)
			let swiftRange = SourceFileRange(
				lineStart: Int(mappingComponents[4])!,
				columnStart: Int(mappingComponents[5])!,
				lineEnd: Int(mappingComponents[6])!,
				columnEnd: Int(mappingComponents[7])!)
			return Mapping(kotlinRange: kotlinRange, swiftRange: swiftRange)
		}
	}

	func getSwiftRange(forKotlinLine line: Int, column: Int) -> SourceFileRange? {
		for mapping in mappings {
			if compare(
					line1: mapping.kotlinRange.lineStart,
					column1: mapping.kotlinRange.columnStart,
					isBeforeLine2: line,
					column2: column),
				compare(
					line1: line,
					column1: column,
					isBeforeLine2: mapping.kotlinRange.lineEnd,
					column2: mapping.kotlinRange.columnEnd)
			{
				return mapping.swiftRange
			}
		}

		return nil
	}

	func compare(line1: Int, column1: Int, isBeforeLine2 line2: Int, column2: Int) -> Bool {
		if line1 < line2 {
			return true
		}
		else if line1 == line2 {
			if column1 <= column2 {
				return true
			}
		}

		return false
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
var input: [String] = []

// Read all the input, separated into lines
while let nextLine = readLine(strippingNewline: false) {
	input.append(nextLine)
}

// Get only lines with errors and warnings
var errors = input.filter { \(dollarSign)0.hasPrefix("e: ") || \(dollarSign)0.hasPrefix("w: ") }

// Handle the errors
var errorMaps: [String: ErrorMap] = [:]
for error in errors {
	let errorInformation = getInformation(fromString: error)
	let errorMapPath =
		"\(SupportingFile.kotlinErrorMapsFolder)/" + errorInformation.filePath.dropLast(2) +
		"kotlinErrorMap"

	if errorMaps[errorMapPath] == nil {
		if let fileContents = try? String(contentsOfFile: errorMapPath) {
			errorMaps[errorMapPath] = ErrorMap(
				kotlinFilePath: errorInformation.filePath,
				contents: fileContents)
		}
		else {
			// Print error with the available information
			let errorString = errorInformation.isError ? "error" : "warning"
			print("\\(getAbsoultePath(forFile: errorInformation.filePath)):" +
				"\\(errorInformation.lineNumber):" +
				"\\(errorInformation.columnNumber): " +
				"\\(errorString):\\(errorInformation.errorMessage)")
			continue
		}
	}

	let errorMap = errorMaps[errorMapPath]!

	if let swiftRange = errorMap.getSwiftRange(
		forKotlinLine: errorInformation.lineNumber,
		column: errorInformation.columnNumber)
	{
		let errorString = errorInformation.isError ? "error" : "warning"
		print("\\(getAbsoultePath(forFile: errorMap.swiftFilePath)):\\(swiftRange.lineStart):" +
			"\\(swiftRange.columnStart): \\(errorString):\\(errorInformation.errorMessage)")
	}
	else {
		// Print error with the available information
		let errorString = errorInformation.isError ? "error" : "warning"
		print("\\(getAbsoultePath(forFile: errorMap.swiftFilePath)):" +
			"0:0: \\(errorString):\\(errorInformation.errorMessage)")
	}
}

if !errors.isEmpty {
	exit(-1)
}

"""

// gryphon multiline
internal let makeGryphonTargetsFileContents = """
require 'xcodeproj'

if ARGV.length < 1
    STDERR.puts "Error: please specify the path to the Xcode project as an argument."
    exit(false)
end

project_path = ARGV[0]
project = Xcodeproj::Project.open(project_path)

gryphonTargetName = "Gryphon"
gryphonBuildPhaseName = "Call Gryphon"
kotlinTargetName = "Kotlin"
kotlinBuildPhaseName = "Compile Kotlin"

####################################################################################################
# Make the Gryphon target

# Create the new target (or fetch it if it exists)
gryphonTarget = project.targets.detect { |target| target.name == gryphonTargetName }
if gryphonTarget == nil
	puts "	Creating new Gryphon target..."
	gryphonTarget = project.new_aggregate_target(gryphonTargetName)
else
	puts "	Updating Gryphon target..."
end

# Set the product name of the target (otherwise Xcode may complain)
# Set the build settings so that only the "My Mac" platform is available
gryphonTarget.build_configurations.each do |config|
	config.build_settings["PRODUCT_NAME"] = "Gryphon"
	config.build_settings["SUPPORTED_PLATFORMS"] = "macosx"
	config.build_settings["SUPPORTS_MACCATALYST"] = "FALSE"
end

# Create a new run script build phase (or fetch it if it exists)
gryphonBuildPhase = gryphonTarget.shell_script_build_phases.detect { |buildPhase|
	buildPhase.name == gryphonBuildPhaseName
}
if gryphonBuildPhase == nil
	puts "	Creating new Run Script build phase..."
	gryphonBuildPhase = gryphonTarget.new_shell_script_build_phase(gryphonBuildPhaseName)
else
	puts "	Updating Run Script build phase..."
end

# Create the script we want to run

script = "gryphon \\"\(dollarSign){PROJECT_NAME}.xcodeproj\\"" +
	" \\"\(dollarSign){SRCROOT}/\(SupportingFile.xcFileList.relativePath)\\"" +
	" --verbose"

# Add any other argument directly to the script (dropping the xcode project first)
for argument in ARGV.slice(1...)
	puts "	Including " + argument
    script = script + " " + argument
end

gryphonBuildPhase.shell_script = script

####################################################################################################
# Make the Kotlin target

# Create the new target (or fetch it if it exists)
kotlinTarget = project.targets.detect { |target| target.name == kotlinTargetName }
if kotlinTarget == nil
	puts "	Creating new Kotlin target..."
	kotlinTarget = project.new_aggregate_target(kotlinTargetName)
else
	puts "	Updating Kotlin target..."
end

# Set the product name of the target (otherwise Xcode may complain)
# Set the build settings so that only the "My Mac" platform is available
# Create a new build setting for setting the Android project's folder
kotlinTarget.build_configurations.each do |config|
	config.build_settings["PRODUCT_NAME"] = "Kotlin"
	config.build_settings["SUPPORTED_PLATFORMS"] = "macosx"
	config.build_settings["SUPPORTS_MACCATALYST"] = "FALSE"

	# Don't overwrite the Android root folder the user if the user sets it manually
	if config.build_settings["ANDROID_ROOT"] == nil
		config.build_settings["ANDROID_ROOT"] = "../Android"
	end
end

# Create a new run script build phase (or fetch it if it exists)
kotlinBuildPhase = kotlinTarget.shell_script_build_phases.detect { |buildPhase|
	buildPhase.name == kotlinBuildPhaseName
}
if kotlinBuildPhase == nil
	puts "	Creating new Run Script build phase..."
	kotlinBuildPhase = kotlinTarget.new_shell_script_build_phase(kotlinBuildPhaseName)
else
	puts "	Updating Run Script build phase..."
end

# Set the script we want to run
kotlinBuildPhase.shell_script =
	"bash \(SupportingFile.compileKotlinRelativePath)"

####################################################################################################
# Save the changes to disk
project.save()

"""

// gryphon multiline
internal let compileKotlinFileContents = """
# Exit if any command fails
set -e

# Remove old logs
# The `-f` option is here to avoid reporting errors when the files are not found
rm -f "\(dollarSign)SRCROOT/\(SupportingFile.gryphonBuildFolder)/gradleOutput.txt"
rm -f "\(dollarSign)SRCROOT/\(SupportingFile.gryphonBuildFolder)/gradleErrors.txt"

# Switch to the Android folder so we can use pre-built gradle info to speed up the compilation.
cd "\(dollarSign)ANDROID_ROOT"

# Compile the Android sources and save the logs gack to the iOS folder
# This command is allowed to fail so we add "|| true" to the end
./gradlew compileDebugSources > \
	"\(dollarSign)SRCROOT/\(SupportingFile.gryphonBuildFolder)/gradleOutput.txt" 2> \
	"\(dollarSign)SRCROOT/\(SupportingFile.gryphonBuildFolder)/gradleErrors.txt" \
	|| true

# Switch back to the iOS folder
cd \(dollarSign)SRCROOT

# Map the Kotlin errors back to Swift
swift \(SupportingFile.mapGradleErrorsToSwiftRelativePath) < \
	\(SupportingFile.gryphonBuildFolder)/gradleOutput.txt

swift \(SupportingFile.mapGradleErrorsToSwiftRelativePath) < \
	\(SupportingFile.gryphonBuildFolder)/gradleErrors.txt

"""

/// Stores all hard-coded file names and paths. Changes to these paths might need to be reflected in
/// prepareForBootstrapTests.sh
public class SupportingFile {
	let name: String
	/// The folder where this file should be. A value of `nil` corresponds to the current directory.
	let folder: String?
	let contents: String?

	private init(_ name: String, folder: String?, contents: String?) {
		self.name = name
		self.folder = folder
		self.contents = contents
	}

	var relativePath: String {
		if let folder = self.folder {
			return "\(folder)/\(name)"
		}
		else {
			return name
		}
	}

	var absolutePath: String {
		return Utilities.getAbsoultePath(forFile: relativePath)
	}

	//
	static public func pathOfSwiftASTDumpFile(
		forSwiftFile swiftFile: String,
		swiftVersion: String)
		-> String
	{
		let relativePath = Utilities.getRelativePath(forFile: swiftFile)
		let pathInGryphonFolder = "\(astDumpsFolder)-Swift-\(swiftVersion)/\(relativePath)"
		let astDumpPath = Utilities.changeExtension(of: pathInGryphonFolder, to: .swiftASTDump)
		return astDumpPath
	}

	static public func pathOfKotlinErrorMapFile(forKotlinFile kotlinFile: String) -> String {
		let relativePath = Utilities.getRelativePath(forFile: kotlinFile)
		let pathInGryphonFolder = "\(kotlinErrorMapsFolder)/\(relativePath)"
		let errorMapPath = Utilities.changeExtension(of: pathInGryphonFolder, to: .kotlinErrorMap)
		return errorMapPath
	}

	// Folders
	public static let gryphonBuildFolder = ".gryphon"
	public static let gryphonScriptsFolder = "\(gryphonBuildFolder)/scripts"
	public static let kotlinErrorMapsFolder = "\(gryphonBuildFolder)/KotlinErrorMaps"
	public static let astDumpsFolder = "\(gryphonBuildFolder)/ASTDumps"

	// Files in the project folder
	public static let xcFileList = SupportingFile(
		"gryphonInputFiles.xcfilelist",
		folder: nil,
		contents: "")
	public static let gryphonSwiftLibrary = SupportingFile(
		"GryphonSwiftLibrary.swift",
		folder: nil,
		contents: gryphonSwiftLibraryFileContents)
	public static let gryphonKotlinLibrary = SupportingFile(
		"GryphonKotlinLibrary.kt",
		folder: nil,
		contents: gryphonKotlinLibraryFileContents)

	// Files in the Gryphon build folder ("/path/to/project/.gryphon")
	public static let gryphonTemplatesLibrary = SupportingFile(
		"GryphonTemplatesLibrary.swift",
		folder: SupportingFile.gryphonBuildFolder,
		contents: gryphonTemplatesLibraryFileContents)
	public static let temporaryOutputFileMap = SupportingFile(
		"output-file-map.json",
		folder: SupportingFile.gryphonBuildFolder,
		contents: nil)
	public static let astDumpsScript = SupportingFile(
		"updateASTDumps.sh",
		folder: SupportingFile.gryphonBuildFolder,
		contents: nil)
	public static let gryphonXCTest = SupportingFile(
		"GryphonXCTest.swift",
		folder: SupportingFile.gryphonBuildFolder,
		contents: gryphonXCTestFileContents)

	// Files in the Gryphon scripts folder ("/path/to/project/.gryphon/scripts")
	public static let mapKotlinErrorsToSwift = SupportingFile(
		"mapKotlinErrorsToSwift.swift",
		folder: SupportingFile.gryphonScriptsFolder,
		contents: mapKotlinErrorsToSwiftFileContents)

	internal static let mapGradleErrorsToSwiftRelativePath =
		".gryphon/scripts/mapGradleErrorsToSwift.swift"
	public static let mapGradleErrorsToSwift = SupportingFile(
		"mapGradleErrorsToSwift.swift",
		folder: SupportingFile.gryphonScriptsFolder,
		contents: mapGradleErrorsToSwiftFileContents)

	public static let makeGryphonTargets = SupportingFile(
		"makeGryphonTargets.rb",
		folder: SupportingFile.gryphonScriptsFolder,
		contents: makeGryphonTargetsFileContents)

	internal static let compileKotlinRelativePath =
		".gryphon/scripts/compileKotlin.sh"
	public static let compileKotlin = SupportingFile(
		"compileKotlin.sh",
		folder: SupportingFile.gryphonScriptsFolder,
		contents: compileKotlinFileContents)

	/// Files that should be created on every init
	static let filesForInitialization: List = [
		gryphonTemplatesLibrary,
		gryphonXCTest,
	]

	static let filesForXcodeInitialization: List = [
		gryphonTemplatesLibrary,
		gryphonXCTest,
		mapKotlinErrorsToSwift,
		mapGradleErrorsToSwift,
		makeGryphonTargets,
		compileKotlin,
	]
}

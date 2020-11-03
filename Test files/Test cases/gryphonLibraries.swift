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

// Gryphon Swift Library

// MARK: - Template class declarations
internal class GRYTemplate { // gryphon ignore
	static func dot(_ left: GRYTemplate, _ right: String) -> GRYDotTemplate {
		return GRYDotTemplate(left, right)
	}

	static func dot(_ left: String, _ right: String) -> GRYDotTemplate {
		return GRYDotTemplate(GRYLiteralTemplate(string: left), right)
	}

	static func call(
		_ function: GRYTemplate,
		_ parameters: [GRYParameterTemplate])
		-> GRYCallTemplate
	{
		return GRYCallTemplate(function, parameters)
	}

	static func call(
		_ function: String,
		_ parameters: [GRYParameterTemplate])
		-> GRYCallTemplate
	{
		return GRYCallTemplate(function, parameters)
	}
}

internal class GRYDotTemplate: GRYTemplate { // gryphon ignore
	let left: GRYTemplate
	let right: String

	init(_ left: GRYTemplate, _ right: String) {
		self.left = left
		self.right = right
	}
}

internal class GRYCallTemplate: GRYTemplate { // gryphon ignore
	let function: GRYTemplate
	let parameters: [GRYParameterTemplate]

	init(_ function: GRYTemplate, _ parameters: [GRYParameterTemplate]) {
		self.function = function
		self.parameters = parameters
	}

	//
	init(_ function: String, _ parameters: [GRYParameterTemplate]) {
		self.function = GRYLiteralTemplate(string: function)
		self.parameters = parameters
	}
}

internal class GRYParameterTemplate: ExpressibleByStringLiteral { // gryphon ignore
	let label: String?
	let template: GRYTemplate

	internal init(_ label: String?, _ template: GRYTemplate) {
		if let existingLabel = label {
			if existingLabel == "_" || existingLabel == "" {
				self.label = nil
			}
			else {
				self.label = label
			}
		}
		else {
			self.label = label
		}

		self.template = template
	}

	required init(stringLiteral: String) {
		self.label = nil
		self.template = GRYLiteralTemplate(string: stringLiteral)
	}

	static func labeledParameter(
		_ label: String?,
		_ template: GRYTemplate)
		-> GRYParameterTemplate
	{
		return GRYParameterTemplate(label, template)
	}

	static func labeledParameter(
		_ label: String?,
		_ template: String)
		-> GRYParameterTemplate
	{
		return GRYParameterTemplate(label, GRYLiteralTemplate(string: template))
	}

	static func dot(
		_ left: GRYTemplate,
		_ right: String)
		-> GRYParameterTemplate
	{
		return GRYParameterTemplate(nil, GRYDotTemplate(left, right))
	}

	static func dot(
		_ left: String,
		_ right: String)
		-> GRYParameterTemplate
	{
		return GRYParameterTemplate(nil, GRYDotTemplate(GRYLiteralTemplate(string: left), right))
	}

	static func call(
		_ function: GRYTemplate,
		_ parameters: [GRYParameterTemplate])
		-> GRYParameterTemplate
	{
		return GRYParameterTemplate(nil, GRYCallTemplate(function, parameters))
	}

	static func call(
		_ function: String,
		_ parameters: [GRYParameterTemplate])
		-> GRYParameterTemplate
	{
		return GRYParameterTemplate(nil, GRYCallTemplate(function, parameters))
	}
}

internal class GRYLiteralTemplate: GRYTemplate { // gryphon ignore
	let string: String

	init(string: String) {
		self.string = string
	}
}

internal class GRYConcatenatedTemplate: GRYTemplate { // gryphon ignore
	let left: GRYTemplate
	let right: GRYTemplate

	init(left: GRYTemplate, right: GRYTemplate) {
		self.left = left
		self.right = right
	}
}

internal func + ( // gryphon ignore
	left: GRYTemplate,
	right: GRYTemplate)
	-> GRYConcatenatedTemplate
{
	GRYConcatenatedTemplate(left: left, right: right)
}

internal func + (left: String, right: GRYTemplate) -> GRYConcatenatedTemplate { // gryphon ignore
	GRYConcatenatedTemplate(left: GRYLiteralTemplate(string: left), right: right)
}

internal func + (left: GRYTemplate, right: String) -> GRYConcatenatedTemplate { // gryphon ignore
	GRYConcatenatedTemplate(left: left, right: GRYLiteralTemplate(string: right))
}

// MARK: - Templates
// Replacement for Comparable
private struct _Comparable: Comparable { // gryphon ignore
	static func < (lhs: _Comparable, rhs: _Comparable) -> Bool {
		return false
	}
}

private func gryphonTemplates() { // gryphon ignore
	let _array1: MutableList<Any> = [1, 2, 3]
	let _array2: MutableList<Any> = [1, 2, 3]
	let _any: Any = 0
	let _string: String = ""
	let _index = _string.startIndex
	let _comparableArray: List<_Comparable> = []
	let _closure: (_Comparable, _Comparable) -> Bool = { _, _ in true }

	// Templates with an input that references methods defined in this file
	_ = zip(_array1, _array2)
	_ = GRYTemplate.call(.dot("_array1", "zip"), ["_array2"])

	_ = _array1.toList()
	_ = GRYTemplate.call(.dot("_array1", "toList"), [])

	_ = _array1.appending(_any)
	_ = "_array1 + _any"

	_ = _array1.appending(contentsOf: _array2)
	_ = "_array1 + _array2"

	// Templates with an output that references methods defined in the GryphonKotlinLibrary.kt file
	_ = _string.suffix(from: _index)
	_ = GRYTemplate.call(.dot("_string", "suffix"), [.labeledParameter("startIndex", "_index")])

	_ = _comparableArray.sorted(by: _closure)
	_ = GRYTemplate.call(
		.dot("_comparableArray", "sorted"), [.labeledParameter("isAscending", "_closure")])

	_ = _array1.removeLast()
	_ = GRYTemplate.call(.dot("_array1", "removeLast"), [])
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Collections

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
		return List(array.dropFirst(k))
	}

	public func dropLast(_ k: Int = 1) -> List<Element> {
		return List(array.dropLast(k))
	}

	public func drop(while predicate: (Element) throws -> Bool) rethrows -> List<Element> {
		return try List(array.drop(while: predicate))
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

	public func removeAll(keepingCapacity keepCapacity: Bool = false) {
		array.removeAll(keepingCapacity: keepCapacity)
	}

	public func reverse() {
		self.array = self.array.reversed()
	}

	override public func drop(while predicate: (Element) throws -> Bool) rethrows -> List<Element> {
		return try List(array.drop(while: predicate))
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
		return List(dictionary).map { ($0.0, $0.1) }
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

////////////////////////////////////////////////////////////////////////////////////////////////////
// Gryphon Kotlin Library

// gryphon insert: import java.lang.ClassCastException
// gryphon insert:
// gryphon insert: fun String.suffix(startIndex: Int): String {
// gryphon insert:     return this.substring(startIndex, this.length)
// gryphon insert: }
// gryphon insert:
// gryphon insert: fun <T> MutableList<T>.removeLast() {
// gryphon insert:     this.removeAt(this.size - 1)
// gryphon insert: }
// gryphon insert:
// gryphon insert: fun String.indexOrNull(character: Char): Int? {
// gryphon insert:     val result = this.indexOf(character)
// gryphon insert:     if (result == -1) {
// gryphon insert:         return null
// gryphon insert:     }
// gryphon insert:     else {
// gryphon insert:         return result
// gryphon insert:     }
// gryphon insert: }
// gryphon insert:
// gryphon insert: @Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
// gryphon insert: inline fun <reified T> List<*>.castOrNull(): List<T>? {
// gryphon insert:     if (this.all { it is T }) {
// gryphon insert:         return this as List<T>
// gryphon insert:     }
// gryphon insert:     else {
// gryphon insert:         return null
// gryphon insert:     }
// gryphon insert: }
// gryphon insert:
// gryphon insert: @Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
// gryphon insert: inline fun <reified T> List<*>.castMutableOrNull(): MutableList<T>? {
// gryphon insert:     if (this.all { it is T }) {
// gryphon insert:         return (this as List<T>).toMutableList()
// gryphon insert:     }
// gryphon insert:     else {
// gryphon insert:         return null
// gryphon insert:     }
// gryphon insert: }
// gryphon insert:
// gryphon insert: @Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
// gryphon insert: inline fun <reified K, reified V> Map<*, *>.castOrNull()
// gryphon insert:     : Map<K, V>?
// gryphon insert: {
// gryphon insert:     if (this.all { it.key is K && it.value is V }) {
// gryphon insert:         return this as Map<K, V>
// gryphon insert:     }
// gryphon insert:     else {
// gryphon insert:         return null
// gryphon insert:     }
// gryphon insert: }
// gryphon insert:
// gryphon insert: @Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
// gryphon insert: inline fun <reified K, reified V> Map<*, *>.castMutableOrNull()
// gryphon insert:     : MutableMap<K, V>?
// gryphon insert: {
// gryphon insert:     if (this.all { it.key is K && it.value is V }) {
// gryphon insert:         return (this as Map<K, V>).toMutableMap()
// gryphon insert:     }
// gryphon insert:     else {
// gryphon insert:         return null
// gryphon insert:     }
// gryphon insert: }
// gryphon insert:
// gryphon insert:
// gryphon insert: @Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
// gryphon insert: inline fun <reified T> List<*>.cast(): List<T> {
// gryphon insert:     if (this.all { it is T }) {
// gryphon insert:         return this as List<T>
// gryphon insert:     }
// gryphon insert:     else {
// gryphon insert:         throw ClassCastException()
// gryphon insert:     }
// gryphon insert: }
// gryphon insert:
// gryphon insert: @Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
// gryphon insert: inline fun <reified T> List<*>.castMutable(): MutableList<T> {
// gryphon insert:     if (this.all { it is T }) {
// gryphon insert:         return (this as List<T>).toMutableList()
// gryphon insert:     }
// gryphon insert:     else {
// gryphon insert:         throw ClassCastException()
// gryphon insert:     }
// gryphon insert: }
// gryphon insert:
// gryphon insert: @Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
// gryphon insert: inline fun <reified K, reified V> Map<*, *>.cast()
// gryphon insert:     : Map<K, V>
// gryphon insert: {
// gryphon insert:     if (this.all { it.key is K && it.value is V }) {
// gryphon insert:         return this as Map<K, V>
// gryphon insert:     }
// gryphon insert:     else {
// gryphon insert:         throw ClassCastException()
// gryphon insert:     }
// gryphon insert: }
// gryphon insert:
// gryphon insert: @Suppress("UNCHECKED_CAST", "UNUSED_PARAMETER")
// gryphon insert: inline fun <reified K, reified V> Map<*, *>.castMutable()
// gryphon insert:     : MutableMap<K, V>
// gryphon insert: {
// gryphon insert:     if (this.all { it.key is K && it.value is V }) {
// gryphon insert:         return (this as Map<K, V>).toMutableMap()
// gryphon insert:     }
// gryphon insert:     else {
// gryphon insert:         throw ClassCastException()
// gryphon insert:     }
// gryphon insert: }
// gryphon insert:
// gryphon insert: fun <Element> List<Element>.sorted(
// gryphon insert:     isAscending: (Element, Element) -> Boolean)
// gryphon insert:     : MutableList<Element>
// gryphon insert: {
// gryphon insert:     val copyList = this.toMutableList()
// gryphon insert:     copyList.quicksort(0, this.size - 1, isAscending)
// gryphon insert:     return copyList
// gryphon insert: }
// gryphon insert:
// gryphon insert: fun <Element> MutableList<Element>.quicksort(
// gryphon insert:     left: Int,
// gryphon insert:     right: Int,
// gryphon insert:     isAscending: (Element, Element) -> Boolean)
// gryphon insert: {
// gryphon insert:     if (left < right) {
// gryphon insert:         val pivot = this.partition(left, right, isAscending)
// gryphon insert:         this.quicksort(left, pivot - 1, isAscending)
// gryphon insert:         this.quicksort(pivot + 1, right, isAscending)
// gryphon insert:     }
// gryphon insert: }
// gryphon insert:
// gryphon insert: fun <Element> MutableList<Element>.partition(
// gryphon insert:     left: Int,
// gryphon insert:     right: Int,
// gryphon insert:     isAscending: (Element, Element) -> Boolean)
// gryphon insert:     : Int
// gryphon insert: {
// gryphon insert:     val pivot = this[right]
// gryphon insert:
// gryphon insert:     var i = left - 1
// gryphon insert:
// gryphon insert:     var j = left
// gryphon insert:     while (j <= right - 1) {
// gryphon insert:         if (isAscending(this[j], pivot)) {
// gryphon insert:             i += 1
// gryphon insert:
// gryphon insert:             val aux = this[i]
// gryphon insert:             this[i] = this[j]
// gryphon insert:             this[j] = aux
// gryphon insert:         }
// gryphon insert:
// gryphon insert:         j += 1
// gryphon insert:     }
// gryphon insert:
// gryphon insert:     val aux = this[i + 1]
// gryphon insert:     this[i + 1] = this[right]
// gryphon insert:     this[right] = aux
// gryphon insert:
// gryphon insert:     return i + 1
// gryphon insert: }

////////////////////////////////////////////////////////////////////////////////////////////////////

// Test casts
let strings: List<String> = ["abc", "def"]
let anys = strings.as(List<Any>.self)
print(anys)

let mutableAnys = strings.as(MutableList<Any>.self)
print(mutableAnys)

let forcedAnys = strings.forceCast(to: List<Any>.self)
print(forcedAnys)

let mutableForcedAnys = strings.forceCast(to: MutableList<Any>.self)
print(mutableForcedAnys)

let failedCast1 = strings.as(List<Int>.self)
print(failedCast1)

let anys2: List<Any> = ["", 0]
let failedCast2 = anys2.as(List<String>.self)
print(failedCast2)

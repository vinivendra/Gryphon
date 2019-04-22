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

// MARK: - Swift standard library

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

	public init<T>(_ arrayReference: ArrayClass<T>) {
		self.array = arrayReference.array as! Buffer
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

	public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> ArrayClass<Element> {
		return try ArrayClass(self.array.filter(isIncluded))
	}

	public func map<T>(_ transform: (Element) throws -> T) rethrows -> ArrayClass<T> {
		return try ArrayClass<T>(self.array.map(transform))
	}

	public func compactMap<T>(_ transform: (Element) throws -> T?) rethrows -> ArrayClass<T> {
		return try ArrayClass<T>(self.array.compactMap(transform))
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

	public func removeFirst() -> Element {
		return array.removeFirst()
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

public func zipToClass<Element1, Element2>( // kotlin: ignore
	_ array1: ArrayClass<Element1>,
	_ array2: ArrayClass<Element2>)
	-> ArrayClass<(Element1, Element2)>
{
	return ArrayClass(Array(zip(array1, array2)))
}

/// According to https://swiftdoc.org/v4.2/type/dictionary/hierarchy/
/// the Dictionary type in Swift conforms exactly to these protocols,
/// plus CustomReflectable (which is beyond Gryphon's scope for now).
public final class DictionaryClass<Key, Value>: // kotlin: ignore
	ExpressibleByDictionaryLiteral, CustomStringConvertible, CustomDebugStringConvertible,
	Collection
	where Key: Hashable
{
	public typealias Buffer = [Key: Value]

	public var dictionary: Buffer

	public init(_ dictionary: Buffer) {
		self.dictionary = dictionary
	}

	public init<K, V>(_ dictionaryReference: DictionaryClass<K, V>) {
		self.dictionary = dictionaryReference.dictionary as! Buffer
	}

	public func copy() -> DictionaryClass<Key, Value> {
		return DictionaryClass(dictionary)
	}

	// Expressible By Dictionary Literal
	public required init(dictionaryLiteral elements: (Key, Value)...) {
		self.dictionary = Buffer(uniqueKeysWithValues: elements)
	}

	// ...
	public subscript (_ key: Key) -> Value? {
		get {
			return dictionary[key]
		}
		set {
			dictionary[key] = newValue
		}
	}

	// Custom (Debug) String Convertible
	public var description: String {
		return dictionary.description
	}

	public var debugDescription: String {
		return dictionary.debugDescription
	}

	// Collection
	public typealias SubSequence = Slice<[Key: Value]>

	@inlinable public var startIndex: Buffer.Index {
		return dictionary.startIndex
	}

	@inlinable public var endIndex: Buffer.Index {
		return dictionary.endIndex
	}

	@inlinable
	public func index(after i: Buffer.Index) -> Buffer.Index
	{
		return dictionary.index(after: i)
	}

	@inlinable
	public func formIndex(after i: inout Buffer.Index) {
		dictionary.formIndex(after: &i)
	}

	@inlinable
	public func index(forKey key: Key) -> Buffer.Index? {
		return dictionary.index(forKey: key)
	}

	@inlinable
	public subscript(position: Buffer.Index) -> Buffer.Element {
		return dictionary[position]
	}

	@inlinable public var count: Int {
		return dictionary.count
	}

	@inlinable public var isEmpty: Bool {
		return dictionary.isEmpty
	}

	//
	public func map<T>(_ transform: ((key: Key, value: Value)) throws -> T)
		rethrows -> ArrayClass<T>
	{
		return try ArrayClass<T>(self.dictionary.map(transform))
	}

	@inlinable
	public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> DictionaryClass<Key, T> {
		return try DictionaryClass<Key, T>(dictionary.mapValues(transform))
	}
}

extension DictionaryClass: Equatable where Value: Equatable { // kotlin: ignore
	public static func == (
		lhs: DictionaryClass, rhs: DictionaryClass) -> Bool
	{
		return lhs.dictionary == rhs.dictionary
	}
}

extension DictionaryClass: Hashable where Value: Hashable { // kotlin: ignore
	public func hash(into hasher: inout Hasher) {
		dictionary.hash(into: &hasher)
	}
}

extension DictionaryClass: Codable where Key: Codable, Value: Codable { // kotlin: ignore
	public func encode(to encoder: Encoder) throws {
		try dictionary.encode(to: encoder)
	}

	public convenience init(from decoder: Decoder) throws {
		try self.init(Buffer(from: decoder))
	}
}

// MARK: - Kotlin standard library

// declaration: fun <T> MutableList<T>.copy(): MutableList<T> {
// declaration: 	return this.toMutableList()
// declaration: }

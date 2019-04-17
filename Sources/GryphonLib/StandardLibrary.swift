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
public final class ArrayReference<Element>: // kotlin: ignore
	ExpressibleByArrayLiteral, CustomStringConvertible, CustomDebugStringConvertible,
	RandomAccessCollection, MutableCollection, RangeReplaceableCollection
{
	public typealias Buffer = [Element]

	public var array: Buffer

	public init(array: Buffer) {
		self.array = array
	}

	public init<T>(_ arrayReference: ArrayReference<T>) {
		self.array = arrayReference.array as! Buffer
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

	public func appending(_ newElement: Element) -> ArrayReference<Element> {
		return ArrayReference<Element>(array: self.array + [newElement])
	}

	public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> ArrayReference<Element> {
		return try ArrayReference(array: self.array.filter(isIncluded))
	}

	public func map<T>(_ transform: (Element) throws -> T) rethrows -> ArrayReference<T> {
		return try ArrayReference<T>(array: self.array.map(transform))
	}

	public func compactMap<T>(_ transform: (Element) throws -> T?) rethrows -> ArrayReference<T> {
		return try ArrayReference<T>(array: self.array.compactMap(transform))
	}

	public func appending<S>(contentsOf newElements: S) -> ArrayReference<Element>
		where S: Sequence, Element == S.Element
	{
		return ArrayReference<Element>(array: self.array + newElements)
	}

	public func removeFirst() -> Element {
		return array.removeFirst()
	}
}

extension ArrayReference: Equatable where Element: Equatable { // kotlin: ignore
	public static func == (lhs: ArrayReference, rhs: ArrayReference) -> Bool {
		return lhs.array == rhs.array
	}

	//
	public func index(of element: Element) -> Int? {
		return array.index(of: element)
	}
}

extension ArrayReference: Hashable where Element: Hashable { // kotlin: ignore
	public func hash(into hasher: inout Hasher) {
		array.hash(into: &hasher)
	}
}

extension ArrayReference: Codable where Element: Codable { // kotlin: ignore
	public func encode(to encoder: Encoder) throws {
		try array.encode(to: encoder)
	}

	public convenience init(from decoder: Decoder) throws {
		try self.init(array: Buffer(from: decoder))
	}
}

/// According to https://swiftdoc.org/v4.2/type/dictionary/hierarchy/
/// the Dictionary type in Swift conforms exactly to these protocols,
/// plus CustomReflectable (which is beyond Gryphon's scope for now).
public final class DictionaryReference<Key, Value>: // kotlin: ignore
	ExpressibleByDictionaryLiteral, CustomStringConvertible, CustomDebugStringConvertible,
	Collection
	where Key: Hashable
{
	public typealias Buffer = [Key: Value]

	public var dictionary: Buffer

	public init(dictionary: Buffer) {
		self.dictionary = dictionary
	}

	public init<K, V>(_ dictionaryReference: DictionaryReference<K, V>) {
		self.dictionary = dictionaryReference.dictionary as! Buffer
	}

	public func copy() -> DictionaryReference<Key, Value> {
		return DictionaryReference(dictionary: dictionary)
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
}

extension DictionaryReference: Equatable where Value: Equatable { // kotlin: ignore
	public static func == (
		lhs: DictionaryReference, rhs: DictionaryReference) -> Bool
	{
		return lhs.dictionary == rhs.dictionary
	}
}

extension DictionaryReference: Hashable where Value: Hashable { // kotlin: ignore
	public func hash(into hasher: inout Hasher) {
		dictionary.hash(into: &hasher)
	}
}

extension DictionaryReference: Codable where Key: Codable, Value: Codable { // kotlin: ignore
	public func encode(to encoder: Encoder) throws {
		try dictionary.encode(to: encoder)
	}

	public convenience init(from decoder: Decoder) throws {
		try self.init(dictionary: Buffer(from: decoder))
	}
}

// MARK: - Kotlin standard library

// declaration: fun <T> MutableList<T>.copy(): MutableList<T> {
// declaration: 	return this.toMutableList()
// declaration: }

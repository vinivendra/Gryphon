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

// MARK: - Swift standard library

typealias MultilineString = String

private func gryphonTemplates() {
	let _array1: MutableArray<Any> = [1, 2, 3]
	let _array2: MutableArray<Any> = [1, 2, 3]
	let _string: String = ""
	let _index = _string.startIndex

	_ = zipToClass(_array1, _array2)
	_ = "_array1.zip(_array2)"

	_ = _string.suffix(from: _index)
	_ = "_string.suffix(startIndex = _index)"
}

/// According to http://swiftdoc.org/v4.2/type/Array/hierarchy/
/// (link found via https://www.raywenderlich.com/139591/building-custom-collection-swift)
/// the Array type in Swift conforms exactly to these protocols,
/// plus CustomReflectable (which is beyond Gryphon's scope for now).
public final class MutableArray<Element>: // kotlin: ignore
	ExpressibleByArrayLiteral, CustomStringConvertible, CustomDebugStringConvertible,
	RandomAccessCollection, MutableCollection, RangeReplaceableCollection
{
	public typealias Buffer = [Element]

	public var array: Buffer

	public init(_ array: Buffer) {
		self.array = array
	}

	public init<T>(_ mutableArray: MutableArray<T>) {
		self.array = mutableArray.array as! Buffer
	}

	public func `as`<CastedType>(
		_ type: MutableArray<CastedType>.Type)
		-> MutableArray<CastedType>?
	{
		if let castedArray = self.array as? [CastedType] {
			return MutableArray<CastedType>(castedArray)
		}
		else {
			return nil
		}
	}

	public func copy() -> MutableArray<Element> {
		return MutableArray(array)
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

	public func appending(_ newElement: Element) -> MutableArray<Element> {
		return MutableArray<Element>(self.array + [newElement])
	}

	public func insert(_ newElement: Element, at i: Index) {
		array.insert(newElement, at: i)
	}

	public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> MutableArray<Element> {
		return try MutableArray(self.array.filter(isIncluded))
	}

	public func map<T>(_ transform: (Element) throws -> T) rethrows -> MutableArray<T> {
		return try MutableArray<T>(self.array.map(transform))
	}

	public func compactMap<T>(_ transform: (Element) throws -> T?) rethrows -> MutableArray<T> {
		return try MutableArray<T>(self.array.compactMap(transform))
	}

	public func flatMap<SegmentOfResult>(
		_ transform: (Element) throws -> SegmentOfResult)
		rethrows -> MutableArray<SegmentOfResult.Element>
		where SegmentOfResult: Sequence
	{
		return try MutableArray<SegmentOfResult.Element>(array.flatMap(transform))
	}

	@inlinable
	public func sorted(
		by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows
		-> MutableArray<Element>
	{
		return MutableArray(try array.sorted(by: areInIncreasingOrder))
	}

	public func appending<S>(contentsOf newElements: S) -> MutableArray<Element>
		where S: Sequence, Element == S.Element
	{
		return MutableArray<Element>(self.array + newElements)
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

extension MutableArray: Equatable where Element: Equatable { // kotlin: ignore
	public static func == (lhs: MutableArray, rhs: MutableArray) -> Bool {
		return lhs.array == rhs.array
	}

	//
	public func index(of element: Element) -> Int? {
		return array.index(of: element)
	}
}

extension MutableArray: Hashable where Element: Hashable { // kotlin: ignore
	public func hash(into hasher: inout Hasher) {
		array.hash(into: &hasher)
	}
}

extension MutableArray: Codable where Element: Codable { // kotlin: ignore
	public func encode(to encoder: Encoder) throws {
		try array.encode(to: encoder)
	}

	public convenience init(from decoder: Decoder) throws {
		try self.init(Buffer(from: decoder))
	}
}

extension MutableArray where Element: Comparable { // kotlin: ignore
	@inlinable
	public func sorted() -> MutableArray<Element> {
		return MutableArray(array.sorted())
	}
}

public protocol BackedByArray { // kotlin: ignore
	associatedtype Element
	var arrayBacking: [Element] { get }
}

extension MutableArray: BackedByArray { // kotlin: ignore
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
	-> MutableArray<(Element1, Element2)>
	where Array1: BackedByArray,
	Array2: BackedByArray,
	Element1 == Array1.Element,
	Element2 == Array2.Element
{
	return MutableArray(Array(zip(array1.arrayBacking, array2.arrayBacking)))
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

extension FixedArray: BackedByArray { // kotlin: ignore
	public var arrayBacking: [Element] {
		return self.array
	}
}

/// According to https://swiftdoc.org/v4.2/type/dictionary/hierarchy/
/// the Dictionary type in Swift conforms exactly to these protocols,
/// plus CustomReflectable (which is beyond Gryphon's scope for now).
public final class MutableDictionary<Key, Value>: // kotlin: ignore
	ExpressibleByDictionaryLiteral, CustomStringConvertible, CustomDebugStringConvertible,
	Collection
	where Key: Hashable
{
	public typealias Buffer = [Key: Value]
	public typealias KeyValueTuple = (key: Key, value: Value)

	public var dictionary: Buffer

	public init(_ dictionary: Buffer) {
		self.dictionary = dictionary
	}

	public init<K, V>(_ mutableDictionary: MutableDictionary<K, V>) {
		self.dictionary = mutableDictionary.dictionary as! Buffer
	}

	public func copy() -> MutableDictionary<Key, Value> {
		return MutableDictionary(dictionary)
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
	public func map<T>(_ transform: (KeyValueTuple) throws -> T)
		rethrows -> MutableArray<T>
	{
		return try MutableArray<T>(self.dictionary.map(transform))
	}

	@inlinable
	public func mapValues<T>(
		_ transform: (Value) throws -> T)
		rethrows -> MutableDictionary<Key, T>
	{
		return try MutableDictionary<Key, T>(dictionary.mapValues(transform))
	}

	@inlinable
	public func sorted(
		by areInIncreasingOrder: (KeyValueTuple, KeyValueTuple) throws -> Bool)
		rethrows -> MutableArray<KeyValueTuple>
	{
		return MutableArray<KeyValueTuple>(try dictionary.sorted(by: areInIncreasingOrder))
	}
}

extension MutableDictionary: Equatable where Value: Equatable { // kotlin: ignore
	public static func == (
		lhs: MutableDictionary, rhs: MutableDictionary) -> Bool
	{
		return lhs.dictionary == rhs.dictionary
	}
}

extension MutableDictionary: Hashable where Value: Hashable { // kotlin: ignore
	public func hash(into hasher: inout Hasher) {
		dictionary.hash(into: &hasher)
	}
}

extension MutableDictionary: Codable where Key: Codable, Value: Codable { // kotlin: ignore
	public func encode(to encoder: Encoder) throws {
		try dictionary.encode(to: encoder)
	}

	public convenience init(from decoder: Decoder) throws {
		try self.init(Buffer(from: decoder))
	}
}

/// According to https://swiftdoc.org/v4.2/type/dictionary/hierarchy/
/// the Dictionary type in Swift conforms exactly to these protocols,
/// plus CustomReflectable (which is beyond Gryphon's scope for now).
public struct FixedDictionary<Key, Value>: // kotlin: ignore
	ExpressibleByDictionaryLiteral, CustomStringConvertible, CustomDebugStringConvertible,
	Collection
	where Key: Hashable
{
	public typealias Buffer = [Key: Value]
	public typealias KeyValueTuple = (key: Key, value: Value)

	public let dictionary: Buffer

	public init(_ dictionary: Buffer) {
		self.dictionary = dictionary
	}

	public init<K, V>(_ fixedDictionary: FixedDictionary<K, V>) {
		self.dictionary = fixedDictionary.dictionary as! Buffer
	}

	public func copy() -> FixedDictionary<Key, Value> {
		return FixedDictionary(dictionary)
	}

	// Expressible By Dictionary Literal
	public init(dictionaryLiteral elements: (Key, Value)...) {
		self.dictionary = Buffer(uniqueKeysWithValues: elements)
	}

	// ...
	public subscript (_ key: Key) -> Value? {
		return dictionary[key]
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
	public func map<T>(_ transform: (KeyValueTuple) throws -> T)
		rethrows -> MutableArray<T>
	{
		return try MutableArray<T>(self.dictionary.map(transform))
	}

	@inlinable
	public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> FixedDictionary<Key, T> {
		return try FixedDictionary<Key, T>(dictionary.mapValues(transform))
	}

	@inlinable
	public func sorted(
		by areInIncreasingOrder: (KeyValueTuple, KeyValueTuple) throws -> Bool)
		rethrows -> MutableArray<KeyValueTuple>
	{
		return MutableArray<KeyValueTuple>(try dictionary.sorted(by: areInIncreasingOrder))
	}
}

extension FixedDictionary: Equatable where Value: Equatable { // kotlin: ignore
	public static func == (
		lhs: FixedDictionary, rhs: FixedDictionary) -> Bool
	{
		return lhs.dictionary == rhs.dictionary
	}
}

extension FixedDictionary: Hashable where Value: Hashable { // kotlin: ignore
	public func hash(into hasher: inout Hasher) {
		dictionary.hash(into: &hasher)
	}
}

extension FixedDictionary: Codable where Key: Codable, Value: Codable { // kotlin: ignore
	public func encode(to encoder: Encoder) throws {
		try dictionary.encode(to: encoder)
	}

	public init(from decoder: Decoder) throws {
		try self.init(Buffer(from: decoder))
	}
}

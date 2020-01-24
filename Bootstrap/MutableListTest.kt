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
open class MutableListTest: XCTestCase {
    constructor(): super() { }

    override public fun getClassName(): String {
        return "MutableListTest"
    }

    override public fun runAllTests() {
        testEquatable()
        testInits()
        testPassingByReference()
        testCasting()
        testCopy()
        testToList()
        testSubscript()
        testDescription()
        testCollectionIndices()
        testIsEmpty()
        testFirst()
        testLast()
        testIndexBefore()
        testAppendContentsOf()
        testAppend()
        testAppending()
        testInsert()
        testFilter()
        testMap()
        testCompactMap()
        testFlatMap()
        testSortedBy()
        testAppendingContentsOf()
        testRemoveFirst()
        testRemoveLast()
        testReverse()
        testIndices()
        testIndexOfElement()
        testSorted()
        testZipToClass()
    }

    // MARK: - Tests
    internal fun testEquatable() {
        val list1: MutableList<Int> = mutableListOf(1, 2, 3)
        val list2: MutableList<Int> = mutableListOf(1, 2, 3)
        val list3: MutableList<Int> = mutableListOf(4, 5, 6)

        XCTAssert(list1 == list2)
        XCTAssertFalse(list2 == list3)
    }

    internal fun testInits() {
        val list1: MutableList<Int> = mutableListOf(1, 2, 3)
        val list2: MutableList<Int> = listOf(1, 2, 3).toMutableList<Int>()
        val list5: MutableList<Int> = mutableListOf<Int>()
        val list6: MutableList<Int> = mutableListOf()

        XCTAssertEqual(list1, list2)
        XCTAssertEqual(list5, list6)

        list1.add(4)
        list5.add(4)

        XCTAssertNotEqual(list1, list2)
        XCTAssertNotEqual(list5, list6)
        XCTAssertEqual(list2, mutableListOf(1, 2, 3))
    }

    internal fun testPassingByReference() {
        val list1: MutableList<Int> = mutableListOf(1, 2, 3)
        val list2: MutableList<Int> = list1

        list1[0] = 10

        XCTAssertEqual(list1, list2)
    }

    internal fun testCasting() {
        val list1: MutableList<Any> = mutableListOf(1, 2, 3)
        val failedCast: MutableList<String>? = list1 as? MutableList<String>
        val successfulCast: MutableList<Int>? = list1 as? MutableList<Int>

        XCTAssertNil(failedCast)
        XCTAssertNotNil(successfulCast)
        XCTAssertEqual(successfulCast, mutableListOf(1, 2, 3))
    }

    internal fun testCopy() {
        val list1: MutableList<Int> = mutableListOf(1, 2, 3)
        val list2: MutableList<Int> = list1.toMutableList()

        list1[0] = 10

        XCTAssertNotEqual(list1, list2)
    }

    internal fun testToList() {
        val list1: MutableList<Int> = mutableListOf(1, 2, 3)
        val list2: MutableList<Int> = mutableListOf(1, 2, 3, 4)
        val list: List<Int> = list1.toList()

        XCTAssert(list1 == list)
        XCTAssert(list == list1)
        XCTAssert(list2 != list)
        XCTAssert(list != list2)
    }

    internal fun testSubscript() {
        val list1: MutableList<Int> = mutableListOf(1, 2, 3)
        val list2: MutableList<Int> = mutableListOf(10, 2, 3)

        list1[0] = 10

        XCTAssertEqual(list1, list2)
        XCTAssertEqual(list1[0], 10)
        XCTAssertEqual(list1[1], 2)
        XCTAssertEqual(list1[2], 3)
    }

    internal fun testDescription() {
        val list: MutableList<Int> = mutableListOf(1, 2, 3)

        XCTAssert(list.toString().contains("1"))
        XCTAssert(list.toString().contains("2"))
        XCTAssert(list.toString().contains("3"))
        XCTAssert(!list.toString().contains("4"))
    }

    internal fun testCollectionIndices() {
        val list: MutableList<Int> = mutableListOf(1, 2, 3)
        val middleIndex: Int = 0 + 1
        val lastIndex: Int = middleIndex + 1
        val endIndex: Int = lastIndex + 1

        // Test start index
        XCTAssertEqual(list[0], 1)

        // Test index(after:)
        XCTAssertEqual(list[middleIndex], 2)
        XCTAssertEqual(list[lastIndex], 3)

        // Test endIndex
        XCTAssertEqual(endIndex, list.size)
        XCTAssertNotEqual(lastIndex, list.size)
    }

    internal fun testIsEmpty() {
        val list: MutableList<Int> = mutableListOf(1, 2, 3)
        val emptyArray: MutableList<Int> = mutableListOf()

        XCTAssert(!list.isEmpty())
        XCTAssert(emptyArray.isEmpty())
    }

    internal fun testFirst() {
        val list: MutableList<Int> = mutableListOf(1, 2, 3)
        val emptyArray: MutableList<Int> = mutableListOf()

        XCTAssertEqual(list.firstOrNull(), 1)
        XCTAssertEqual(emptyArray.firstOrNull(), null)
    }

    internal fun testLast() {
        val list: MutableList<Int> = mutableListOf(1, 2, 3)
        val emptyArray: MutableList<Int> = mutableListOf()

        XCTAssertEqual(list.lastOrNull(), 3)
        XCTAssertEqual(emptyArray.lastOrNull(), null)
    }

    internal fun testIndexBefore() {
        val list: MutableList<Int> = mutableListOf(1, 2, 3)
        val lastIndex: Int = list.size - 1
        XCTAssertEqual(list[lastIndex], 3)
    }

    internal fun testAppendContentsOf() {
        val list1: MutableList<Int> = mutableListOf(1, 2, 3)
        val list2: MutableList<Int> = mutableListOf(4, 5, 6)

        list1.addAll(list2)

        XCTAssertEqual(list1, mutableListOf(1, 2, 3, 4, 5, 6))
    }

    internal fun testAppend() {
        val list1: MutableList<Int> = mutableListOf(1, 2, 3)
        list1.add(4)
        XCTAssertEqual(list1, mutableListOf(1, 2, 3, 4))
    }

    internal fun testAppending() {
        val list1: MutableList<Int> = mutableListOf(1, 2, 3)
        val list2: List<Int> = list1 + 4

        XCTAssertEqual(list2, listOf(1, 2, 3, 4))
        XCTAssertEqual(list1, mutableListOf(1, 2, 3))
    }

    internal fun testInsert() {
        val list1: MutableList<Int> = mutableListOf(1, 2, 3)

        list1.add(0, 0)

        XCTAssertEqual(list1, mutableListOf(0, 1, 2, 3))

        list1.add(2, 10)

        XCTAssertEqual(list1, mutableListOf(0, 1, 10, 2, 3))

        list1.add(5, 10)

        XCTAssertEqual(list1, mutableListOf(0, 1, 10, 2, 3, 10))
    }

    internal fun testFilter() {
        val list1: MutableList<Int> = mutableListOf(1, 2, 3)
        val list2: List<Int> = list1.filter { it > 1 }.toMutableList()

        XCTAssertEqual(list1, mutableListOf(1, 2, 3))
        XCTAssertEqual(list2, listOf(2, 3))
    }

    internal fun testMap() {
        val list1: MutableList<Int> = mutableListOf(1, 2, 3)
        val list2: List<Int> = list1.map { it * 2 }.toMutableList()

        XCTAssertEqual(list1, mutableListOf(1, 2, 3))
        XCTAssertEqual(list2, listOf(2, 4, 6))
    }

    internal fun testCompactMap() {
        val list1: MutableList<Int> = mutableListOf(1, 2, 3)
        val list2: List<Int> = list1.map { e -> if (e == 2) { e } else { null } }.filterNotNull().toMutableList()

        XCTAssertEqual(list1, mutableListOf(1, 2, 3))
        XCTAssertEqual(list2, listOf(2))
    }

    internal fun testFlatMap() {
        val list1: MutableList<Int> = mutableListOf(1, 2, 3)
        val list2: List<Int> = list1.flatMap { mutableListOf(it, 10 * it) }.toMutableList()

        XCTAssertEqual(list1, mutableListOf(1, 2, 3))
        XCTAssertEqual(list2, listOf(1, 10, 2, 20, 3, 30))
    }

    internal fun testSortedBy() {
        val list1: MutableList<Int> = mutableListOf(3, 1, 2)
        val list2: MutableList<Int> = mutableListOf(1, 2, 3)
        val sortedArray1: List<Int> = list1.sorted(isAscending = { a, b -> a < b })
        val sortedArray2: List<Int> = list2.sorted(isAscending = { a, b -> a < b })
        val sortedArray2Descending: List<Int> = list2.sorted(isAscending = { a, b -> a > b })

        XCTAssertEqual(sortedArray1, listOf(1, 2, 3))
        XCTAssertEqual(list1, mutableListOf(3, 1, 2))
        XCTAssertEqual(sortedArray2, listOf(1, 2, 3))
        XCTAssertEqual(sortedArray2Descending, listOf(3, 2, 1))
    }

    internal fun testAppendingContentsOf() {
        val list1: MutableList<Int> = mutableListOf(1, 2, 3)
        val list2: MutableList<Int> = mutableListOf(4, 5, 6)
        val list3: MutableList<Int> = mutableListOf(7, 8, 9)

        XCTAssertEqual(list1 + list2, listOf(1, 2, 3, 4, 5, 6))
        XCTAssertEqual(list1, mutableListOf(1, 2, 3))
        XCTAssertEqual(list2, mutableListOf(4, 5, 6))
        XCTAssertEqual(list1 + list3, listOf(1, 2, 3, 7, 8, 9))
        XCTAssertEqual(list1, mutableListOf(1, 2, 3))
        XCTAssertEqual(list3, mutableListOf(7, 8, 9))
    }

    internal fun testRemoveFirst() {
        val list: MutableList<Int> = mutableListOf(1, 2, 3)
        list.removeAt(0)
        XCTAssertEqual(list, mutableListOf(2, 3))
    }

    internal fun testRemoveLast() {
        val list: MutableList<Int> = mutableListOf(1, 2, 3)
        list.removeLast()
        XCTAssertEqual(list, mutableListOf(1, 2))
    }

    internal fun testReverse() {
        val list: MutableList<Int> = mutableListOf(1, 2, 3)
        list.reverse()
        XCTAssertEqual(list, mutableListOf(3, 2, 1))
    }

    internal fun testIndices() {
        val list: MutableList<Int> = mutableListOf(1, 2, 3)
        XCTAssertEqual(list.indices, 0 until 3)
    }

    internal fun testIndexOfElement() {
        val list: MutableList<Int> = mutableListOf(1, 2, 10)

        XCTAssertEqual(list.indexOf(1), 0)
        XCTAssertEqual(list.indexOf(2), 1)
        XCTAssertEqual(list.indexOf(10), 2)
    }

    internal fun testSorted() {
        val list1: MutableList<Int> = mutableListOf(3, 2, 1)
        val list2: MutableList<Int> = mutableListOf(1, 2, 3)

        XCTAssertEqual(list1.sorted(), mutableListOf(1, 2, 3))
        XCTAssertEqual(list1, mutableListOf(3, 2, 1))
        XCTAssertEqual(list2.sorted(), mutableListOf(1, 2, 3))
    }

    internal fun testZipToClass() {
        val list1: MutableList<Int> = mutableListOf(3, 2, 1)
        val list2: MutableList<Int> = mutableListOf(1, 2, 3)
        for ((a, b) in list1.zip(list2)) {
            XCTAssertEqual(a + b, 4)
        }
    }
}

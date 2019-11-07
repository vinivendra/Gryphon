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
data class TranslationResult(
    val translation: String,
    val errorMap: String
)

open class Translation {
    val swiftRange: SourceFileRange?
    val children: MutableList<TranslationUnit> = mutableListOf()

    constructor(range: SourceFileRange?) {
        this.swiftRange = range
    }

    constructor(range: SourceFileRange?, string: String) {
        this.swiftRange = range
        this.append(string)
    }

    internal fun append(string: String) {
        children.add(TranslationUnit(string))
    }

    internal fun append(map: Translation) {
        children.add(TranslationUnit(map))
    }

    val isEmpty: Boolean
        get() {
            if (children.isEmpty()) {
                return true
            }
            for (child in children) {
                val string: String? = child.stringLiteral
                if (string != null) {
                    if (string != "") {
                        return false
                    }
                }
                else {
                    if (!(child.node!!.isEmpty)) {
                        return false
                    }
                }
            }
            return true
        }

    public fun resolveTranslation(): TranslationResult {
        val translationResult: MutableList<String> = mutableListOf()
        val errorMap: MutableList<String> = mutableListOf()

        resolveTranslationInto(translationResult = translationResult, errorMap = errorMap)

        return TranslationResult(
            translation = translationResult.joinToString(separator = ""),
            errorMap = errorMap.joinToString(separator = "\n"))
    }

    private fun resolveTranslationInto(
        translationResult: MutableList<String>,
        errorMap: MutableList<String>,
        currentPosition: SourceFilePosition = SourceFilePosition())
    {
        val startingPosition: SourceFilePosition = currentPosition.copy()

        for (child in children) {
            val string: String? = child.stringLiteral
            if (string != null) {
                currentPosition.updateWithString(string)
                translationResult.add(string)
            }
            else {
                val node: Translation = child.node!!
                node.resolveTranslationInto(
                    translationResult = translationResult,
                    errorMap = errorMap,
                    currentPosition = currentPosition)
            }
        }

        val swiftRange: SourceFileRange? = swiftRange

        if (swiftRange != null) {
            val endPosition: SourceFilePosition = currentPosition.copy()
            errorMap.add("${swiftRange.lineStart}:${swiftRange.columnStart}, " + "${swiftRange.lineEnd}:${swiftRange.columnEnd} -> " + "${startingPosition.lineNumber}:${startingPosition.columnNumber}, " + "${endPosition.lineNumber}:${endPosition.columnNumber}")
        }
    }

    /// Goes through the translation subtree looking for the given suffix. If it is found, it is
    /// dropped from the tree (in-place). Otherwise, nothing happens.
    public fun dropLast(string: String) {
        val lastUnit: TranslationUnit? = children.lastOrNull()
        if (lastUnit != null) {
            val string: String? = lastUnit.stringLiteral
            if (string != null) {
                if (string.endsWith(string)) {
                    val newUnit: TranslationUnit = TranslationUnit(string.dropLast(string.length))
                    children[children.size - 1] = newUnit
                }
            }
            else {
                lastUnit.node!!.dropLast(string)
            }
        }
    }
}

data class TranslationUnit(
    val stringLiteral: String?,
    val node: Translation?
) {
    // Only these two initializers exits, therefore exactly one of the properties will always be
    // non-nil
    constructor(stringLiteral: String) {
        this.stringLiteral = stringLiteral
        this.node = null
    }

    constructor(node: Translation) {
        this.stringLiteral = null
        this.node = node
    }
}

open class SourceFilePosition {
    var lineNumber: Int
    var columnNumber: Int

    constructor() {
        this.lineNumber = 1
        this.columnNumber = 1
    }

    constructor(lineNumber: Int, columnNumber: Int) {
        this.lineNumber = lineNumber
        this.columnNumber = columnNumber
    }

    // Note: ensuring new lines only happen at the end of strings (i.e. all strings already come
    // separated by new lines) could make this more performant.
    internal fun updateWithString(string: String) {
        val newLines: Int = string.occurrences(searchedSubstring = "\n").size
        if (newLines > 0) {
            this.lineNumber += newLines
            val lastLineContents: String = string.split(separator = "\n", omittingEmptySubsequences = false).lastOrNull()!!
            this.columnNumber = lastLineContents.length + 1
        }
        else {
            this.columnNumber += string.length
        }
    }

    internal fun copy(): SourceFilePosition {
        return SourceFilePosition(lineNumber = this.lineNumber, columnNumber = this.columnNumber)
    }
}

internal fun Translation.appendTranslations(
    translations: MutableList<Translation>,
    separator: String)
{
    for (translation in translations.dropLast(1)) {
        this.append(translation)
        this.append(separator)
    }
    val lastTranslation: Translation? = translations.lastOrNull()
    if (lastTranslation != null) {
        this.append(lastTranslation)
    }
}

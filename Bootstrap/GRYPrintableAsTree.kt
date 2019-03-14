class GRYPrintableTree: GRYPrintableAsTree {
	companion object {
		internal fun initOrNil(
			description: String,
			subtreesOrNil: MutableList<GRYPrintableAsTree?>)
			: GRYPrintableTree?
		{
			val subtrees: MutableList<GRYPrintableAsTree?> = mutableListOf()

			for (subtree in subtreesOrNil) {
				val unwrapped: GRYPrintableAsTree? = subtree
				if (unwrapped != null) {
					subtrees.add(unwrapped)
				}
			}

			if (subtrees.isEmpty()) {
				return null
			}

			return GRYPrintableTree(description, subtrees)
		}

		internal fun initOrNil(description: String?): GRYPrintableTree? {
			if (description != null) {
				return GRYPrintableTree(description)
			}
			else {
				return null
			}
		}
	}

	override var treeDescription: String = ""
	override var printableSubtrees: MutableList<GRYPrintableAsTree?> = mutableListOf()

	constructor(description: String) {
		this.treeDescription = description
		return
	}

	constructor(description: String, subtrees: MutableList<GRYPrintableAsTree?>) {
		this.treeDescription = description
		this.printableSubtrees = subtrees
		return
	}

	constructor(array: MutableList<GRYPrintableAsTree?>) {
		this.treeDescription = "Array"
		this.printableSubtrees = array
		return
	}

	internal fun addChild(child: GRYPrintableAsTree?) {
		printableSubtrees.add(child)
	}
}

interface GRYPrintableAsTree {
	val treeDescription: String
	val printableSubtrees: MutableList<GRYPrintableAsTree?>
}

public fun GRYPrintableAsTree.prettyPrint(
	indentation: MutableList<String> = mutableListOf(),
	isLast: Boolean = true,
	horizontalLimit: Int = Int.MAX_VALUE,
	printFunction: (String) -> Unit = { print(it) })
{
	val indentationString: String = indentation.joinToString(separator = "")
	val rawLine: String = "${indentationString} ${treeDescription}"
	val line: String

	if (rawLine.length > horizontalLimit) {
		line = rawLine.substring(0, horizontalLimit - 1) + "…"
	}
	else {
		line = rawLine
	}

	printFunction(line + "\n")

	if (!indentation.isEmpty()) {
		if (isLast) {
			indentation[indentation.size - 1] = "   "
		}
		else {
			indentation[indentation.size - 1] = " │ "
		}
	}

	val subtrees: MutableList<GRYPrintableAsTree> = mutableListOf()

	for (element in printableSubtrees) {
		val unwrapped: GRYPrintableAsTree? = element
		if (unwrapped != null) {
			subtrees.add(unwrapped)
		}
	}

	for (subtree in subtrees.dropLast(1)) {
		val newIndentation: MutableList<String> = indentation.copy()
		newIndentation.add(" ├─")
		subtree.prettyPrint(
			indentation = newIndentation,
			isLast = false,
			horizontalLimit = horizontalLimit,
			printFunction = printFunction)
	}

	val newIndentation: MutableList<String> = indentation.copy()

	newIndentation.add(" └─")

	subtrees.lastOrNull()?.prettyPrint(
		indentation = newIndentation,
		isLast = true,
		horizontalLimit = horizontalLimit,
		printFunction = printFunction)
}

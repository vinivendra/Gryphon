class PrintableTree: PrintableAsTree {
	companion object {
		internal fun initOrNil(
			description: String,
			subtreesOrNil: MutableList<PrintableAsTree?>)
			: PrintableTree?
		{
			val subtrees: MutableList<PrintableAsTree?> = mutableListOf()

			for (subtree in subtreesOrNil) {
				val unwrapped: PrintableAsTree? = subtree
				if (unwrapped != null) {
					subtrees.add(unwrapped)
				}
			}

			if (subtrees.isEmpty()) {
				return null
			}

			return PrintableTree(description, subtrees)
		}

		internal fun initOrNil(description: String?): PrintableTree? {
			if (description != null) {
				return PrintableTree(description)
			}
			else {
				return null
			}
		}
	}

	override var treeDescription: String
	override var printableSubtrees: MutableList<PrintableAsTree?>

	constructor(description: String) {
		this.treeDescription = description
		this.printableSubtrees = mutableListOf()
	}

	constructor(description: String, subtrees: MutableList<PrintableAsTree?>) {
		this.treeDescription = description
		this.printableSubtrees = subtrees
	}

	constructor(array: MutableList<PrintableAsTree?>) {
		this.treeDescription = "Array"
		this.printableSubtrees = array
	}

	internal fun addChild(child: PrintableAsTree?) {
		printableSubtrees.add(child)
	}
}

interface PrintableAsTree {
	val treeDescription: String
	val printableSubtrees: MutableList<PrintableAsTree?>
}

public fun PrintableAsTree.prettyPrint(
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

	val subtrees: MutableList<PrintableAsTree> = mutableListOf()

	for (element in printableSubtrees) {
		val unwrapped: PrintableAsTree? = element
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

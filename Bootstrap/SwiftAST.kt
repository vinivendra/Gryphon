class SwiftAST: PrintableAsTree {
	companion object {
		var horizontalLimitWhenPrinting: Int = Int.MAX_VALUE
	}

	val name: String
	val standaloneAttributes: MutableList<String>
	val keyValueAttributes: MutableMap<String, String>
	val subtrees: MutableList<SwiftAST>

	constructor(name: String, subtrees: MutableList<SwiftAST> = mutableListOf()) {
		this.name = name
		this.standaloneAttributes = mutableListOf()
		this.keyValueAttributes = mutableMapOf()
		this.subtrees = subtrees
	}

	constructor(
		name: String,
		standaloneAttributes: MutableList<String>,
		keyValueAttributes: MutableMap<String, String>,
		subtrees: MutableList<SwiftAST> = mutableListOf())
	{
		this.name = name
		this.standaloneAttributes = standaloneAttributes
		this.keyValueAttributes = keyValueAttributes
		this.subtrees = subtrees
	}

	operator internal fun get(key: String): String? {
		return keyValueAttributes[key]
	}

	internal fun subtree(name: String): SwiftAST? {
		return subtrees.find { it.name == name }
	}

	internal fun subtree(index: Int): SwiftAST? {
		if (!(index >= 0 && index < subtrees.size)) {
			return null
		}
		return subtrees[index]
	}

	internal fun subtree(index: Int, name: String): SwiftAST? {
		if (!(index >= 0 && index < subtrees.size)) {
			return null
		}

		val subtree: SwiftAST = subtrees[index]

		if (subtree.name != name) {
			return null
		}

		return subtree
	}

	override val treeDescription: String
		get() {
			return name
		}
	override val printableSubtrees: MutableList<PrintableAsTree?>
		get() {
			val keyValueStrings: MutableList<PrintableTree> = keyValueAttributes.map { "${it.key} → ${it.value}" }.sorted().map { PrintableTree(it) }
			val keyValueArray: MutableList<PrintableAsTree?> = keyValueStrings as MutableList<PrintableAsTree?>
			val standaloneAttributesArray: MutableList<PrintableAsTree?> = standaloneAttributes.map { PrintableTree(it) } as MutableList<PrintableAsTree?>
			val subtreesArray: MutableList<PrintableAsTree?> = subtrees as MutableList<PrintableAsTree?>

			val result = (standaloneAttributesArray + keyValueArray + subtreesArray)
				.toMutableList()

			return result
		}

	override fun toString(): String {
		return this.prettyDescription()
	}

	public fun description(horizontalLimit: Int): String {
		var result: String = ""
		this.prettyPrint(horizontalLimit = horizontalLimit, printFunction = { result += it })
		return result
	}
}

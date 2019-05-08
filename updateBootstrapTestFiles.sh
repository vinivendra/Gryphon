echo "➡️ [1/6] Building Gryphon..."

if swift build
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to build Gryphon."
	exit $?
fi


echo "➡️ [2/6] Dumping the Swift ASTs..."

if perl dumpTranspilerAST.pl
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to dump the Swift ASTs."
	exit $?
fi


echo "➡️ [3/6] Transpiling the Gryphon source files to Kotlin..."

if bash transpileBootstrappedTranspiler.sh
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to transpile the Gryphon source files."
	exit $?
fi


echo "➡️ [4/6] Compiling Kotlin files..."

if bash buildBootstrappedTranspiler.sh
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to compile Kotlin files."
	exit $?
fi


echo "➡️ [5/6] Updating the Swift AST test files..."

if java -jar Bootstrap/kotlin.jar -emit-swiftAST \
		Test\ Files/*.swift -output-file-map=output-file-map-tests.json
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to update the Swift AST test files."
	exit $?
fi


echo "➡️ [6/6] Updating the Raw AST test files..."

if java -jar Bootstrap/kotlin.jar -emit-rawAST \
		Test\ Files/*.swift -output-file-map=output-file-map-tests.json
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to update the Raw AST test files."
	exit $?
fi

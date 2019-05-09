echo "➡️ [1/7] Running pre-build script..."

if bash preBuildScript.sh
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to run pre-build script."
	exit $?
fi


echo "➡️ [2/7] Building Gryphon..."

if swift build
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to build Gryphon."
	exit $?
fi


echo "➡️ [3/7] Dumping the Swift ASTs..."

if perl dumpTranspilerAST.pl
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to dump the Swift ASTs."
	exit $?
fi


echo "➡️ [4/7] Transpiling the Gryphon source files to Kotlin..."

if bash transpileBootstrappedTranspiler.sh
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to transpile the Gryphon source files."
	exit $?
fi


echo "➡️ [5/7] Compiling Kotlin files..."

if bash buildBootstrappedTranspiler.sh
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to compile Kotlin files."
	exit $?
fi


echo "➡️ [6/7] Updating the Swift AST test files..."

if java -jar Bootstrap/kotlin.jar -emit-swiftAST \
		Test\ Files/*.swift -output-file-map=output-file-map-tests.json
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to update the Swift AST test files."
	exit $?
fi


echo "➡️ [7/7] Updating the Raw AST test files..."

if java -jar Bootstrap/kotlin.jar -emit-rawAST \
		Test\ Files/*.swift -output-file-map=output-file-map-tests.json
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to update the Raw AST test files."
	exit $?
fi

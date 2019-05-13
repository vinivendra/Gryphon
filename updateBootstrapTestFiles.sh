echo "➡️ [1/9] Running pre-build script..."

if bash preBuildScript.sh
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to run pre-build script."
	exit $?
fi


echo "➡️ [2/9] Building Gryphon..."

if swift build
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to build Gryphon."
	exit $?
fi


echo "➡️ [3/9] Dumping the Swift ASTs..."

if perl dumpTranspilerAST.pl
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to dump the Swift ASTs."
	exit $?
fi


echo "➡️ [4/9] Transpiling the Gryphon source files to Kotlin..."

if bash transpileBootstrappedTranspiler.sh
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to transpile the Gryphon source files."
	exit $?
fi


echo "➡️ [5/9] Compiling Kotlin files..."

if bash buildBootstrappedTranspiler.sh
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to compile Kotlin files."
	exit $?
fi


echo "➡️ [6/9] Updating the Swift AST test files..."

if java -jar Bootstrap/kotlin.jar -emit-swiftAST \
		Test\ Files/*.swift -output-file-map=output-file-map-tests.json
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to update the Swift AST test files."
	exit $?
fi


echo "➡️ [7/9] Updating the Raw AST test files..."

if java -jar Bootstrap/kotlin.jar -emit-rawAST \
		Test\ Files/*.swift -output-file-map=output-file-map-tests.json
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to update the Raw AST test files."
	exit $?
fi


echo "➡️ [8/9] Updating the AST test files..."

if java -jar Bootstrap/kotlin.jar -emit-AST \
		Test\ Files/*.swift -output-file-map=output-file-map-tests.json
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to update the AST test files."
	exit $?
fi


echo "➡️ [9/9] Updating the .kttest test files..."

if java -jar Bootstrap/kotlin.jar -emit-kotlin \
		Test\ Files/*.swift -output-file-map=output-file-map-tests.json -indentation=4
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to update the .kttest test files."
	exit $?
fi

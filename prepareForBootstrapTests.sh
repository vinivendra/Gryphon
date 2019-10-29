echo "➡️ [1/5] Compiling Kotlin files..."

if bash buildBootstrappedTranspiler.sh
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to compile Kotlin files."
	exit $?
fi


echo "➡️ [2/5] Updating the Swift AST test files..."

if java -jar Bootstrap/kotlin.jar -emit-swiftAST \
		Test\ Files/*.swift -output-file-map=output-file-map-tests.json
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to update the Swift AST test files."
	exit $?
fi


echo "➡️ [4/5] Updating the Raw AST test files..."

if java -jar Bootstrap/kotlin.jar -emit-rawAST \
		Test\ Files/*.swift -output-file-map=output-file-map-tests.json
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to update the Raw AST test files."
	exit $?
fi


echo "➡️ [5/5] Updating the AST test files..."

if java -jar Bootstrap/kotlin.jar -emit-AST \
		Test\ Files/*.swift -output-file-map=output-file-map-tests.json
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to update the AST test files."
	exit $?
fi


echo "➡️ [9/5] Updating the .kttest test files..."

if java -jar Bootstrap/kotlin.jar -emit-kotlin \
		Test\ Files/*.swift -output-file-map=output-file-map-tests.json -indentation=4
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to update the .kttest test files."
	exit $?
fi

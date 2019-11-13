echo "➡️ [1/2] Compiling Kotlin files..."

if bash buildBootstrappedTranspiler.sh 2> .gryphon/kotlinErrors.errors
then
	swift .gryphon/scripts/mapKotlinErrorsToSwift.swift < .gryphon/kotlinErrors.errors
	echo "✅ Done."
	echo ""
else
	swift .gryphon/scripts/mapKotlinErrorsToSwift.swift < .gryphon/kotlinErrors.errors
	echo "🚨 Failed to compile Kotlin files."
	exit -1
fi


echo "➡️ [2/2] Updating the bootstrap outputs..."

for file in Test\ Files/*.swift
do
	echo "	↪️ Updating $file..."
	if java -jar Bootstrap/kotlin.jar -indentation=t -skipASTDumps \
		-emit-swiftAST -emit-rawAST -emit-AST -emit-kotlin \
		"$file"
	then
		echo "	  ✅ Done."
	else
		echo "🚨 Failed!"
		exit -1
	fi
done

echo "✅ Done."

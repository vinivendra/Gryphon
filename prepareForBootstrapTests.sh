echo "➡️ [1/2] Compiling Kotlin files..."

if bash buildBootstrappedTranspiler.sh
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to compile Kotlin files."
	exit $?
fi


echo "➡️ [2/2] Updating the bootstrap outputs..."

for file in Test\ Files/*.swift
do
	echo "	↪️ Updating $file..."
	if java -jar Bootstrap/kotlin.jar -indentation=t \
		-emit-swiftAST -emit-rawAST -emit-AST -emit-kotlin \
		"$file"
	then
		echo "	  ✅ Done."
	else
		echo "🚨 Failed!"
		exit $?
	fi
done

echo "✅ Done."

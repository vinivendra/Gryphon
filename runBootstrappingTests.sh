#!/bin/bash

echo "➡️ [1/6] Building Gryphon..."

if swift build
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to build Gryphon."
	exit -1
fi


echo "➡️ [2/6] Initializing Gryphon (old)..."

cd "gryphon-old"

if ./../.build/debug/Gryphon init -xcode
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to build Gryphon."
	exit -1
fi

cd ..


echo "➡️ [3/6] Transpiling the Gryphon (old) source files to Kotlin..."

if bash transpileGryphonSources.sh
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to transpile the Gryphon source files."
	exit -1
fi


echo "➡️ [4/6] Compiling Kotlin files..."

if bash buildBootstrappedTranspiler.sh 2> .gryphon/kotlinErrors.errors
then
	echo "✅ Done."
	echo ""
else
	swift .gryphon/scripts/mapKotlinErrorsToSwift.swift < .gryphon/kotlinErrors.errors
	echo "🚨 Failed to compile Kotlin files."
	exit -1
fi


echo "➡️ [5/6] Building Gryphon (old)..."

cd "gryphon-old"

if swift build
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to build Gryphon (old)."
	exit -1
fi

echo "➡️ [6/6] Comparing Gryphon (old) with Gryphon (old) transpiled..."

for file in Test\ cases/*.swift
do
    if [[ $file == *"errors.swift" ]]; then
        echo "    ↪️ Skipping $file..."
	elif [[ $file == *"-swiftSyntax"* ]]; then
		echo "    ↪️ Skipping $file..."
    else
        echo "    ↪️ Testing $file..."

		defaultFinal="";
		if [[ $file == *"-default-final.swift" ]]; then
			defaultFinal="--default-final";
		fi

		representations=("-emit-swiftAST" "-emit-rawAST" "-emit-AST" "-emit-kotlin")
		for representation in "${representations[@]}"
		do

			echo "      ↪️ $representation"

			java -jar Bootstrap/kotlin.jar \
				--indentation=t -avoid-unicode $representation $defaultFinal --write-to-console \
				"$file" > .gryphon/generatedResult.txt 2> .gryphon/errors.txt

			sed -i 'sed' 's/0x[0-9a-z]*/hex/g' .gryphon/generatedResult.txt

			if [[ $? -ne 0 ]]; then
				echo "🚨 failed to generate bootstrap results!"
				cat .gryphon/errors.txt
				exit -1
			fi

			./.build/debug/Gryphon \
				--indentation=t -avoid-unicode $representation $defaultFinal --write-to-console \
				"$file" > .gryphon/expectedResult.txt 2> .gryphon/errors.txt

			sed -i 'sed' 's/0x[0-9a-z]*/hex/g' .gryphon/expectedResult.txt

			if [[ $? -ne 0 ]]; then
				echo "🚨 failed to generate expected results!"
				cat .gryphon/errors.txt
				exit -1
			fi

			if diff .gryphon/generatedResult.txt .gryphon/expectedResult.txt
			then
				echo "      ✅ Succeeded."
			else
				echo "🚨 generated results are different than expected!"
				exit -1
			fi
		done
    fi
done

echo "✅ Done."

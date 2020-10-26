#!/bin/bash

echo "➡️ [1/7] Updating Gryphon (old)..."

set -e

# If the directory doesn't exist yet
if [ ! -d "Test Files/Bootstrap/gryphon-old" ]; then
	echo "	↪️ Cloning..."
	mkdir -p "Test Files/Bootstrap/gryphon-old"
	git clone \
		--branch bootstrap \
		https://github.com/vinivendra/Gryphon.git \
		"Test Files/Bootstrap/gryphon-old"
fi

cd "Test Files/Bootstrap/gryphon-old"
git checkout bootstrap
git pull
cd ../../..

set +e


echo "➡️ [2/7] Building Gryphon..."

if swift build
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to build Gryphon."
	exit -1
fi


echo "➡️ [3/7] Initializing Gryphon (old)..."

cd "Test Files/Bootstrap/gryphon-old"

if ./../../../.build/debug/Gryphon init -xcode
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to build Gryphon."
	exit -1
fi

cd ../../..


echo "➡️ [4/7] Transpiling the Gryphon (old) source files to Kotlin..."

if bash transpileGryphonSources.sh
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to transpile the Gryphon source files."
	exit -1
fi


echo "➡️ [5/7] Compiling Kotlin files..."

if bash buildBootstrappedTranspiler.sh 2> .gryphon/kotlinErrors.errors
then
	echo "✅ Done."
	echo ""
else
	swift .gryphon/scripts/mapKotlinErrorsToSwift.swift < .gryphon/kotlinErrors.errors
	echo "🚨 Failed to compile Kotlin files."
	exit -1
fi


echo "➡️ [6/7] Building Gryphon (old)..."

cd "Test Files/Bootstrap/gryphon-old"

if swift build
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to build Gryphon (old)."
	exit -1
fi

echo "➡️ [7/7] Comparing Gryphon (old) with Gryphon (old) transpiled..."

for file in Test\ cases/*.swift
do
	if [[ $file == *"errors.swift" ]]; then
		echo "	↪️ Skipping $file..."
	elif [[ $file == *"-swiftSyntax"* ]]; then
		echo "	↪️ Skipping $file..."
	else
		echo "	↪️ Testing $file..."

		defaultFinal="";
		if [[ $file == *"-default-final.swift" ]]; then
			defaultFinal="--default-final";
		fi

		representations=("-emit-swiftAST" "-emit-rawAST" "-emit-AST" "-emit-kotlin")
		for representation in "${representations[@]}"
		do

			echo "	  ↪️ $representation"

			java -jar Bootstrap/kotlin.jar \
				--indentation=t -avoid-unicode $representation $defaultFinal --write-to-console \
				"$file" > .gryphon/generatedResult.txt 2> .gryphon/errors.txt

			if [[ $? -ne 0 ]]; then
				echo "🚨 failed to generate bootstrap results!"
				cat .gryphon/errors.txt
				exit -1
			fi

			./.build/debug/Gryphon \
				--indentation=t -avoid-unicode $representation $defaultFinal --write-to-console \
				"$file" > .gryphon/expectedResult.txt 2> .gryphon/errors.txt

			if [[ $? -ne 0 ]]; then
				echo "🚨 failed to generate expected results!"
				cat .gryphon/errors.txt
				exit -1
			fi

			sed -i 'sed' 's/0x[0-9a-z]*/hex/g' .gryphon/generatedResult.txt
			sed -i 'sed' 's/@opened("[0-9A-Z\-]*")/@opened/g' .gryphon/generatedResult.txt

			sed -i 'sed' 's/0x[0-9a-z]*/hex/g' .gryphon/expectedResult.txt
			sed -i 'sed' 's/@opened("[0-9A-Z\-]*")/@opened/g' .gryphon/expectedResult.txt

			if diff .gryphon/generatedResult.txt .gryphon/expectedResult.txt
			then
				echo "	  ✅ Succeeded."
			else
				echo "🚨 generated results are different than expected!"
				exit -1
			fi
		done
	fi
done

echo "✅ Done."

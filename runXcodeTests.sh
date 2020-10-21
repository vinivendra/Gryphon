#!/bin/bash

set -e

echo "➡️ [1/2] Testing initialization..."

cd "iOSTests/GryphoniOSTest"

./../../.build/debug/Gryphon clean
rm -f "gryphonInputFiles.xcfilelist"

rm -rf "GryphoniOSTest.xcodeproj"
cp -r "GryphoniOSTest.model.xcodeproj" "GryphoniOSTest.xcodeproj"

if ./../../.build/debug/Gryphon init "GryphoniOSTest.xcodeproj" -swiftSyntax --verbose
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Initialization tests failed."
	exit -1
fi


echo "➡️ [2/2] Testing transpilation..."

echo "GryphoniOSTest/Model.swift" >> "gryphonInputFiles.xcfilelist"

rm -f output.txt

xcodebuild -project GryphoniOSTest.xcodeproj/ -target Gryphon > output.txt

# If Gryphon raised warnings or errors for the Model.swift file

if [[ $(grep -E "Model\.swift:[0-9]+:[0-9]+: error" output.txt) ]];
then
	echo "🚨 Gryphon raised an error."
	grep -E "Model\.swift:[0-9]+:[0-9]+: error" output.txt
	exit -1
fi

if [[ $(grep -E "Model\.swift:[0-9]+:[0-9]+: warning" output.txt) ]];
then
	echo "🚨 Gryphon raised a warning:"
	grep -E "Model\.swift:[0-9]+:[0-9]+: warning" output.txt
	exit -1
fi

echo "✅ Done."
echo ""

# TODO: Create an Android app
# TODO: Set the Model.swift output to the right path
# TODO: Delete the Model.kt file before, test if it exists and has the right contents after
# TODO: - Test kotlin compilation
# TODO: - Test kotlin warnings (if they exist and are reported in the right place)
# TODO: - Test Gryphon with --target, etc
# TODO: - Rename the iOSTest folder
# TODO: - Add Xcode tests to the runTests.sh script

set +e

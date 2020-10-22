#!/bin/bash

set -e

echo "➡️ [1/3] Resetting the Xcode project..."

cd "iOSTests/GryphoniOSTest"

# Remove Gryphon-generated files
./../../.build/debug/Gryphon clean
rm -f "gryphonInputFiles.xcfilelist"

# Remove the old Xcodeproj, replace it with a clean copy of the backup
rm -rf "GryphoniOSTest.xcodeproj"
cp -r "GryphoniOSTest.model.xcodeproj" "GryphoniOSTest.xcodeproj"

echo "✅ Done."
echo ""


echo "➡️ [2/3] Initializing the Xcode project..."

# Initialize the Xcode project
./../../.build/debug/Gryphon init "GryphoniOSTest.xcodeproj" -swiftSyntax

# Add the "Model.swift" file to the list of files to be translated
echo "GryphoniOSTest/Model.swift" >> "gryphonInputFiles.xcfilelist"

echo "✅ Done."
echo ""


echo "➡️ [3/3] Running the Gryphon target..."

# Remove the previously translated file
rm -f ../GryphonAndroidTest/app/src/main/java/com/gryphon/gryphonandroidtest/Model.kt

# Remove file that stores Gryphon errors and warnings
rm -f output.txt

# Run the Gryphon target
xcodebuild -project GryphoniOSTest.xcodeproj/ -target Gryphon > output.txt

# Check if Gryphon raised warnings or errors for the Model.swift file
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

# Check if the generated code is correct
if [[ $(diff \
	../Model.kt \
	../GryphonAndroidTest/app/src/main/java/com/gryphon/gryphonandroidtest/Model.kt) ]];
then
	echo "🚨 Generated code is different from what was expected."
	diff ../Model.kt ../GryphonAndroidTest/app/src/main/java/com/gryphon/gryphonandroidtest/Model.kt
	exit -1
fi

echo "✅ Done."
echo ""

# TODO: - Test kotlin compilation
# TODO: - Test kotlin warnings (if they exist and are reported in the right place)
# TODO: - Test Gryphon with --target, etc
# TODO: - Rename the iOSTest folder
# TODO: - Add Xcode tests to the runTests.sh script

set +e

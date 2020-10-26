#!/bin/bash

set -e

echo "➡️ [1/5] Resetting the Xcode project..."

cd "XcodeTests/iOS"

# Remove Gryphon-generated files
./../../.build/debug/Gryphon clean
rm -f "gryphonInputFiles.xcfilelist"

# Remove the old Xcodeproj, replace it with a clean copy of the backup
rm -rf "GryphoniOSTest.xcodeproj"
cp -r "GryphoniOSTest.backup.xcodeproj" "GryphoniOSTest.xcodeproj"

# Copy the model file to the right place
cp "../Model.swift" "GryphoniOSTest/Model.swift"

echo "✅ Done."
echo ""


echo "➡️ [2/5] Initializing the Xcode project..."

# Initialize the Xcode project
./../../.build/debug/Gryphon init "GryphoniOSTest.xcodeproj" -swiftSyntax

# Add the "Model.swift" file to the list of files to be translated
echo "GryphoniOSTest/Model.swift" > "gryphonInputFiles.xcfilelist"

echo "✅ Done."
echo ""


echo "➡️ [3/5] Running the Gryphon target..."

# Remove the previously translated file
rm -f ../Android/app/src/main/java/com/gryphon/gryphonandroidtest/Model.kt

# Remove file that stores errors and warnings
rm -f output.txt

# Run the Gryphon target
xcodebuild -project GryphoniOSTest.xcodeproj/ -scheme Gryphon > output.txt

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
	../Android/app/src/main/java/com/gryphon/gryphonandroidtest/Model.kt) ]];
then
	echo "🚨 Generated code is different from what was expected."
	diff ../Model.kt ../Android/app/src/main/java/com/gryphon/gryphonandroidtest/Model.kt
	exit -1
fi

echo "✅ Done."
echo ""


echo "➡️ [4/5] Running the Kotlin target..."

# Remove file that stores errors and warnings
rm -f output.txt

# Run the Kotlin target
xcodebuild -project GryphoniOSTest.xcodeproj/ -scheme Kotlin > output.txt

echo "✅ Done."
echo ""


echo "➡️ [5/5] Testing Kotlin error mapping..."

# Remove file that stores errors and warnings
rm -f output.txt

# Copy the model file with errors
cp "../ModelWithErrors.swift" "GryphoniOSTest/Model.swift"

# Transpile the model file
./../../.build/debug/Gryphon "GryphoniOSTest/Model.swift" -swiftSyntax

# Run the Kotlin target
if [[ $(xcodebuild -project GryphoniOSTest.xcodeproj/ -scheme Kotlin > output.txt 2> /dev/null) ]];
then
	echo "🚨 Expected Kotlin compilation to fail."
	exit -1
fi

# Check if the error was correctly reported
if grep -E "Model.swift:24:37: error" output.txt > /dev/null
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Expected Kotlin to report an error at \"Model.swift:24:37\"."
	exit -1
fi

# TODO: - Test Gryphon with --target, etc
# TODO: - Rename the iOSTest folder
# TODO: - Add Xcode tests to the runTests.sh script

set +e

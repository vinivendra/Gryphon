#!/bin/bash

####################################################################################################
# Read the arguments

isVerbose=""

while test $# -gt 0
do
    case "$1" in
		"-v")
			isVerbose="--verbose"
            ;;
		*)
			echo "Skipping unknown argument '$1'"
			;;
    esac

    shift
done

####################################################################################################
set -e

if uname -s | grep "Darwin"
then
	:
else
	echo "Xcode tests are only supported on on macOS."
	exit 0
fi

# Prints a file only if it exists
safeCat () {
	if [[ -f $1 ]];
	then
		cat $1
	fi
}


echo "➡️ [1/8] Preparing..."

# Install Gryphon (Xcode uses the installed binary, so it should be the one we want to test)
# Remove the existing binary (if needed)
echo "Installing the test binary in /usr/local/bin/gryphon..."
rm -f "/usr/local/bin/gryphon"
# Install our test binary
./Scripts/install.sh

echo "Setting up test files..."

# Set the Android SDK path in the properties file
echo "sdk.dir=/Users/$USER/Library/Android/sdk" > \
	"Test files/XcodeTests/Android/local.properties"

# Remove Gryphon-generated files
cd "Test Files/XcodeTests/iOS"
gryphon clean $isVerbose
rm -f "gryphonInputFiles.xcfilelist"
rm -f "local.config"

# Remove the old Xcodeproj, replace it with a clean copy of the backup
rm -rf "GryphoniOSTest.xcodeproj"
cp -r "GryphoniOSTest.backup.xcodeproj" "GryphoniOSTest.xcodeproj"

# Copy the model file to the right place
cp "../Model.swift" "GryphoniOSTest/Model.swift"

echo "✅ Done."
echo ""


echo "➡️ [2/8] Initializing the Xcode project..."

# Initialize the Xcode project
gryphon init "GryphoniOSTest.xcodeproj" $isVerbose

# Add the "Model.swift" file to the list of files to be translated
echo "GryphoniOSTest/Model.swift" > "gryphonInputFiles.xcfilelist"
# Add a commented file path that should be ignored
echo "# GryphoniOSTest/UnexistingFile.swift" >> "gryphonInputFiles.xcfilelist"

echo "✅ Done."
echo ""


echo "➡️ [3/8] Running the Gryphon target..."

# Remove the previously translated file
rm -f ../Android/app/src/main/java/com/gryphon/gryphonandroidtest/Model.kt

# Remove file that stores errors and warnings
rm -f output.txt


# Run the Gryphon target
set +e
xcodebuild -project GryphoniOSTest.xcodeproj/ -scheme Gryphon > output.txt

# If there was an error
if [ $? -ne 0 ];
then
	echo ""
	echo ""
	echo "🚨 Error running Gryphon target. Printing xcodebuild output:"
	cat output.txt || true
	sleep 3 # Wait for cat to finish printing before exiting
	exit -1
fi

set -e


# Check if Gryphon raised warnings or errors for the Model.swift file
if [[ $(grep -E "Model\.swift:[0-9]+:[0-9]+: error" output.txt) ]];
then
	echo "🚨 Gryphon raised an error:"
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


echo "➡️ [4/8] Resetting the Xcode project..."

# Remove Gryphon-generated files
gryphon clean $isVerbose
rm -f "gryphonInputFiles.xcfilelist"
rm -f "local.config"

# Remove the old Xcodeproj, replace it with a clean copy of the (target) backup
rm -rf "GryphoniOSTest.xcodeproj"
cp -r "GryphoniOSTest.targetBackup.xcodeproj" "GryphoniOSTest.xcodeproj"

# Copy the model file to the right place
cp "../Model.swift" "GryphoniOSTest/Model.swift"

echo "✅ Done."
echo ""


echo "➡️ [5/8] Initializing the Xcode project with '--target'..."

# Initialize the Xcode project
gryphon init "GryphoniOSTest.xcodeproj" --target=GryphoniOSTest $isVerbose

# Add the "Model.swift" file to the list of files to be translated
echo "GryphoniOSTest/Model.swift" > "gryphonInputFiles.xcfilelist"
# Add a commented file path that should be ignored
echo "# GryphoniOSTest/UnexistingFile.swift" >> "gryphonInputFiles.xcfilelist"

echo "✅ Done."
echo ""


echo "➡️ [6/8] Running the Gryphon target..."

# Remove the previously translated file
rm -f ../Android/app/src/main/java/com/gryphon/gryphonandroidtest/Model.kt

# Remove file that stores errors and warnings
rm -f output.txt

# Run the Gryphon target
if xcodebuild -project GryphoniOSTest.xcodeproj/ -scheme Gryphon > output.txt
then
	:
else
	echo "🚨 Error running Gryphon target. Printing xcodebuild output:"
	cat output.txt || true
	sleep 3 # Wait for cat to finish printing before exiting
	exit -1
fi

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


echo "➡️ [7/8] Running the Kotlin target..."

# Remove file that stores errors and warnings
rm -f output.txt

# Run the Kotlin target
if xcodebuild -project GryphoniOSTest.xcodeproj/ -scheme Kotlin > output.txt
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Error running Kotlin target. Printing xcodebuild output:"
	cat output.txt || true
	sleep 3 # Wait for cat to finish printing before exiting
	exit -1
fi


echo "➡️ [8/8] Testing Kotlin error mapping..."

# Remove file that stores errors and warnings
rm -f output.txt

# Copy the model file with errors
cp "../ModelWithErrors.swift" "GryphoniOSTest/Model.swift"

# Transpile the model file
gryphon "GryphoniOSTest/Model.swift" $isVerbose

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
	safeCat output.txt
	sleep 3
	exit -1
fi

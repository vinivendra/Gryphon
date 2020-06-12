#!/bin/bash

echo "➡️ [1/4] Building Gryphon..."

if swift build --build-tests
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to build Gryphon."
	exit -1
fi


echo "➡️ [2/4] Getting the path to the built executable..."

if binaryPath=`swift build --show-bin-path`
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to get the path to the built executable."
	exit -1
fi

executable="$binaryPath/Gryphon"


echo "➡️ [3/4] Initializing Gryphon in current directory..."

if `"$executable" clean init -xcode`
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to initialize Gryphon."
	exit -1
fi


echo "➡️ [4/4] Running tests..."

# Create an empty array for storing the failures
allFailures=()

# Function that runs the tests
# Receives one argument: the file name (e.g. "AcceptanceTest.swift")
# Adds any failures that happen in that test to allFailures
function runTest {
	fileName=$(echo "$1" | cut -f 1 -d '.')

	# Get the OS name then run the tests
	osString=$(uname -a)
	if [[ $osString == *"Darwin"* ]]; then
		# We're in macOS, so swift test prints failures to stderr
		commandErrors=$(swift test --filter "$fileName" 3>&1 1>&2 2>&3 | tee /dev/stderr)
	else
		# Assume we're on Linux and swift test prints failures to stdout
		commandErrors=$(swift test --filter "$fileName" | tee /dev/stderr)
	fi

	# Look for failures (failures include the name of the whole file)
	failures=$(echo "$commandErrors" | grep $1)

	# Remove lines that start with a '['
	# Avoids matches to "[22/47] Compiling GryphonLibTests ASTDumpDecoderTest.swift"
	failures=$(echo "$failures" | grep "^[^\[]")

	if [[ $failures == "" ]]; then
		: # Do nothing
	else
		allFailures+=$failures
		allFailures+=$'\n'
	fi
}

exec 3<> /tmp/foo  #open fd 3.

for file in Tests/GryphonLibTests/*.swift
do
	if [[ $file == *"XCTestManifests.swift" ]]; then
		: # Do nothing
	elif [[ $file == *"TestUtilities.swift" ]]; then
		: # Do nothing
	elif [[ $file == *"PerformanceTest.swift" ]]; then
		: # Do nothing
	elif [[ $file == *"AcceptanceTest.swift" ]]; then
		: # Do nothing
	elif [[ $file == *"BootstrappingTest.swift" ]]; then
		: # Do nothing
	else
		fileNameWithExtension=$(basename $file)

		echo "↪️    Running $fileNameWithExtension..."

		runTest $fileNameWithExtension
	fi
done

# If we have to run AcceptanceTest
if [[ $1 == "-a" ]] || [[ $2 == "-a" ]]; then
	fileNameWithExtension="AcceptanceTest.swift"

	echo "↪️    Running $fileNameWithExtension..."

	runTest $fileNameWithExtension
fi

# If we have to run BootstrappingTest
if [[ $1 == "-b" ]] || [[ $2 == "-b" ]]; then
	echo "👇    Preparing for BootstrappingTest..."

	bash prepareForBootstrapTests.sh

	fileNameWithExtension="BootstrappingTest.swift"

	echo "👆    Done preparing for BootstrappingTest."
	echo "↪️    Running $fileNameWithExtension..."

	runTest $fileNameWithExtension
fi

exec 3>&- #close fd 3.

errorsOutput="$allFailures"\

# If output isn't empty
if [[ $errorsOutput == "" ]]; then
	echo "✅ All tests passed."
else
	echo ""
	echo "🚨 Tests failed:"
    echo "$errorsOutput"
    exit 1
fi

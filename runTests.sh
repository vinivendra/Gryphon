#!/bin/bash

####################################################################################################
# Read the arguments

unitTests=0
acceptanceTests=0
bootstrapTests=0
xcodeTests=0

while test $# -gt 0
do
    case "$1" in
        -u) unitTests=1
            ;;
        -a) acceptanceTests=1
            ;;
        -b) bootstrapTests=1
            ;;
        -x) xcodeTests=1
            ;;
    esac
    shift
done

if [[ unitTests -eq 0 && acceptanceTests -eq 0 && bootstrapTests -eq 0 && xcodeTests -eq 0 ]];
then
	echo "Please specify at least one option:"
	echo "	-u: run unit tests"
	echo "	-a: run acceptance tests"
	echo "	-b: run bootstrap tests"
	echo "	-x: run Xcode tests"
	exit 0
fi


####################################################################################################
# Prepare for the tests

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


####################################################################################################
# Run the tests

exec 3<> /tmp/foo  #open fd 3.


# If we have to run unit tests
if [[ unitTests ]]; then
	echo "👇    Running unit tests..."
	# Indent test output
	exec 4>&1
	exec 1> >(paste /dev/null -)

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
		else
			fileNameWithExtension=$(basename $file)

			echo "↪️    Running $fileNameWithExtension..."

			runTest $fileNameWithExtension
		fi
	done

	# Restore indentation
	exec 1>&4 4>&-
	echo "👆    Done running unit tests."
fi

# If we have to run acceptance tests
if [[ acceptanceTests ]]; then
	echo "👇    Running acceptance tests..."
	# Indent test output
	exec 4>&1
	exec 1> >(paste /dev/null -)

	fileNameWithExtension="AcceptanceTest.swift"

	echo "↪️    Running $fileNameWithExtension..."

	runTest $fileNameWithExtension

	# Restore indentation
	exec 1>&4 4>&-
	echo "👆    Done running acceptance tests."
fi

# If we have to run bootstrapping tests
if [[ bootstrapTests ]]; then
	echo "👇    Running bootstrapping tests..."
	# Indent test output
	exec 4>&1
	exec 1> >(paste /dev/null -)

	if bash runBootstrappingTests.sh
	then
		echo "✅ Bootstrapping tests succeeded."
		echo ""
	else
		allFailures+=$'Bootstrapping tests failed'
	fi

	# Restore indentation
	exec 1>&4 4>&-
	echo "👆    Done running bootstrapping tests."
fi

# If we have to run Xcode tests
if [[ xcodeTests ]]; then
	echo "👇    Running Xcode tests..."
	# Indent test output
	exec 4>&1
	exec 1> >(paste /dev/null -)

	if bash runXcodeTests.sh
	then
		echo "✅ Xcode tests succeeded."
		echo ""
	else
		allFailures+=$'Xcode tests failed'
	fi

	# Restore indentation
	exec 1>&4 4>&-
	echo "👆    Done running Xcode tests."
fi

exec 3>&- #close fd 3.

####################################################################################################
# Check for errors

errorsOutput="$allFailures"

# If output isn't empty
if [[ $errorsOutput == "" ]]; then
	echo "✅ All tests passed."
else
	echo ""
	echo "🚨 Tests failed:"
    echo "$errorsOutput"
    exit 1
fi

echo "➡️ [1/4] Running pre-build script..."

if bash preBuildScript.sh
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to run pre-build script."
	exit -1
fi


echo "➡️ [2/4] Building Gryphon..."

if swift build
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to build Gryphon."
	exit -1
fi


echo "➡️ [3/4] Dumping the Swift ASTs..."

if perl dumpASTs.pl Sources/GryphonLib/*.swift \
	Tests/GryphonLibTests/ASTDumpDecoderTest.swift \
	Tests/GryphonLibTests/CompilerTest.swift \
	Tests/GryphonLibTests/DriverTest.swift \
	Tests/GryphonLibTests/ExtensionsTest.swift \
	Tests/GryphonLibTests/IntegrationTest.swift \
	Tests/GryphonLibTests/SourceFileTest.swift \
	Tests/GryphonLibTests/TranslationResultTest.swift \
	Tests/GryphonLibTests/UtilitiesTest.swift \
	Tests/GryphonLibTests/TestUtilities.swift \
	.gryphon/GryphonXCTest.swift
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to dump the Swift ASTs."
	exit -1
fi


echo "➡️ [4/4] Transpiling the Gryphon source files to Kotlin..."

if bash transpileGryphonSources.sh
then
	echo "✅ Done."
	echo ""
else
	echo "🚨 Failed to transpile the Gryphon source files."
	exit -1
fi

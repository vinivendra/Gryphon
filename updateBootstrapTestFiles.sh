bash buildBootstrappedTranspiler.sh;

java -jar Bootstrap/kotlin.jar -emit-swiftAST \
	Test\ Files/*.swift -output-file-map=output-file-map-tests.json;

java -jar Bootstrap/kotlin.jar -emit-rawAST \
	Test\ Files/*.swift -output-file-map=output-file-map-tests.json;

#!/bin/bash

export JAVA_OPTS="-Xmx2048m"
kotlinc -include-runtime \
	-d gryphon-old/Bootstrap/kotlin.jar \
	Bootstrap/*.kt

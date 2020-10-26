#!/bin/bash

export JAVA_OPTS="-Xmx2048m"
kotlinc -include-runtime \
	-d Test\ files/Bootstrap/gryphon-old/Bootstrap/kotlin.jar \
	Test\ files/Bootstrap/*.kt

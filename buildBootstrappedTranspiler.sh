#!/bin/bash

kotlinc -include-runtime \
	-d Bootstrap/kotlin.jar \
	Bootstrap/*.kt

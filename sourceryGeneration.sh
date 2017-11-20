#!/bin/bash

echo "Checking for Sourcery..."

if [ -f "Sourcery/sourcery" ]; then
	echo "Generating source files: Sources + Templates/Sources -> Sources/Generated"
  
	./Sourcery/sourcery --sources Sources --templates Templates/Sources --output Sources/Lens.generated.swift
else
	echo "Sourcery is not installed, ignoring."
fi

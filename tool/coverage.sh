#!/bin/sh

# Clean out old coverage artifacts
if [ -d "./coverage_report" ]; then
    rm -rf ./coverage_report
fi
if [ -f "./coverage.lcov" ]; then
    rm ./coverage.lcov
fi

# Collect coverage and generate report
pub get
pub run dart_codecov_generator --report-on=lib/ "$@"

# Open HTML report if successful
if [ $? -eq 0 ] && [ -f "./coverage_report/index.html" ]; then
    open coverage_report/index.html
fi
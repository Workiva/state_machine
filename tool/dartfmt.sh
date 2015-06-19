#!/bin/bash

set_exit_code="false"

while getopts "e" flag; do
  case "${flag}" in
    e) set_exit_code="true" ;;
  esac
done

# By default, run the formatter with -w to actually change files.
if [ "$set_exit_code" == "false" ]; then
  pub run dart_style:format example lib test -w
  exit "0"
fi

# If -e was set, do a dry run and set the exit code accordingly.
# This is used for CI builds.
num_lines=$(pub run dart_style:format example lib test -n | wc -l)
if [ "$num_lines" -ne "0" ]; then
  echo "The dartfmt tool needs to be run."
  exit "1"
fi
echo "Your dart code is in good shape!"
#!/bin/bash

VERSION="0.1.1"

TMP_LIST_PATH="/tmp/$(basename $0)-list-$RANDOM"
FILES_DIR=$(pwd)

function printHelp() {
    echo "$(basename $0) [-o | --output] file1 file2 [file3...]"
    echo "  -o  output file name (first + last file names by default)"
    exit
}

if [[ "$#" -eq 1 && ("$1" = "-h" || "$1" = "--help") ]]; then
    printHelp
    exit
elif [[ "$1" = "-v" || "$1" = "--version" ]]; then
    echo "$VERSION"
    exit
fi

if [[ "$1" = "-o" || "$1" = "--output" ]]; then
    if [[ -z "$2" ]]; then
        echo "You have to provide the output file name."
        printHelp
    fi
    OUTPUT="$2"
    FIRST_FILE_INDEX=3
else
    OUTPUT="${1%.*}-$(basename ${@: -1})"
    FIRST_FILE_INDEX=1
fi

if [[ $# -lt $(($FIRST_FILE_INDEX + 1)) ]]; then
    echo "You have to provide at least two files."
    printHelp
fi

for file in "${@: FIRST_FILE_INDEX}"; do
    echo "file $FILES_DIR/$file" >> "$TMP_LIST_PATH"
done

# -safe 0 for "Unsafe file name" error
ffmpeg -f concat -safe 0 -i "$TMP_LIST_PATH" -c copy "$OUTPUT"

rm "$TMP_LIST_PATH"
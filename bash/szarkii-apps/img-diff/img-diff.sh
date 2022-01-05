#!/bin/bash

VERSION="0.1.0"

TMP_DIFFERENCE_FILE_PATH="/tmp/$(basename $0)-img-$RANDOM.jpg"
REFERENCE_FILE_NAME=""
COMPARED_FILE_NAME=""

function printHelp() {
    echo "The script checks how similar the images are and retruns the number. The greater value means more similarity. If images are identical the \"inf\" value is returned."
    echo
    echo "$(basename $0) reference_file compared_file"
    exit
}

if [[ "$#" -eq 1 && ("$1" = "-h" || "$1" = "--help") ]]; then
    printHelp
    exit
elif [[ "$1" = "-v" || "$1" = "--version" ]]; then
    echo "$VERSION"
    exit
elif [[ ! $# -eq 2 ]]; then
    echo "Wrong number of arguments."
    echo
    printHelp
    exit
fi

REFERENCE_FILE_NAME="$1"
COMPARED_FILE_NAME="$2"

function computeDifference {
    magick compare -compose src "$REFERENCE_FILE_NAME" "$COMPARED_FILE_NAME" "$TMP_DIFFERENCE_FILE_PATH"
    magick compare -channel red -metric PSNR "$REFERENCE_FILE_NAME" "$COMPARED_FILE_NAME" "$TMP_DIFFERENCE_FILE_PATH"
}

# magick output is treated as an error output
# 2>&1 redirects stderr to stdout
computeDifference 2>&1

rm "$TMP_DIFFERENCE_FILE_PATH"
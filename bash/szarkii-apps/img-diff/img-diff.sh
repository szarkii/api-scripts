#!/bin/bash

VERSION="1.0.0"

function printHelp() {
    echo "The script checks how similar the images are and retruns the percent. The greater value means more similarity."
    echo
    echo "$(basename $0) reference_image compared_image"
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

function computeDifference {
    referenceImagePath="$1"
    comparedImagePath="$2"

    similarityIndex=$(convert "$referenceImagePath" "$comparedImagePath" -metric ncc -compare -format "%[distortion]" info:)
    similarityPercent=$(echo "scale=0; $similarityIndex * 100 / 1" | bc)
    echo $similarityPercent
}

computeDifference "$(realpath $1)" "$(realpath $2)"
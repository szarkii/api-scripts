#!/bin/bash

VERSION="1.0.0"

function printHelp() {
    echo "Convert video into another format. Dedicated for converting all files in the given directory."
    echo "Usage:   $(basename $0) extension file1 [file2, file3, ...]"
    echo "Example: $(basename $0) mp4 video1.avi video2.webm"
    echo "         extension    ouput file extension supported by ffmpeg (e.g. mp4)"
    exit
}

if [[ "$#" -eq 1 && ("$1" = "-h" || "$1" = "--help") ]]; then
    printHelp
    exit
elif [[ "$1" = "-v" || "$1" = "--version" ]]; then
    echo "$VERSION"
    exit
fi

if [[ "$#" -lt 2 ]]; then
    echo "Invalid arguments."
    printHelp
fi

outputFileExtension="$1"

for inputFilePath in "${@: 2}"; do
    if [[ "$inputFilePath" = *".$outputFileExtension" ]]; then
        continue
    fi

    outputFilePath="${inputFilePath%.*}.$outputFileExtension"

    if [[ -f "$outputFilePath" ]]; then
        echo "$(basename $outputFilePath) exists, omitting $(basename $inputFilePath) conversion."
        continue
    fi
        
    ffmpeg -i "$inputFilePath" "$outputFilePath"
done
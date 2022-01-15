#!/bin/bash

VERSION="0.1.0"

function printHelp() {
    echo "Convert video into another format. Dedicated for converting all files in the given directory."
    echo "$(basename $0) input ext"
    echo "$(basename $0) video.webm mp4"
    echo "  input  video or directory"
    echo "  ext    ouput file extension supported by ffmpeg (e.g. mp4)"
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

input=$(realpath "$1")
outputFileExtension="$2"

if [[ -d "$input" ]]; then
    for fileName in $(ls "$input"); do
        outputFileName="${fileName%.*}.$outputFileExtension"
        
        if [[ -f "$input/$outputFileName" ]]; then
            echo "$outputFileName exists, omitting conversion."
            continue
        fi
        
        ffmpeg -i "$input/$fileName" "$input/$outputFileName"
    done
else
    ffmpeg -i "$input" "${input%.*}.$outputFileExtension"
fi
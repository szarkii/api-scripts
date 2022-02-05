#!/bin/bash

VERSION="0.1.0"
IFS=$'\n'

function printHelp() {
    echo "Sets metadata for music files. Downloads the file if URL is provided."
    echo "Dependencies: kid3-cli"
    echo "$(basename $0) [-t track] [-a artist] [-l album] [-y year] [-g genre] [-u URL] input"
    echo "  input  file or directory (N/A for -u)"
    exit
}

# TODO
function downloadFile() {
    youtube-dl --prefer-ffmpeg --format "bestaudio/best" --extract-audio --audio-quality 0 --audio-format mp3 --output "$DIR/$name.%(ext)s" "$url"
}

function setMetadata() {
    track="$1"
    artist="$2"
    album="$3"
    year="$4"
    genre="$5"
    filePath="$6"
    fileName="$(basename "$filePath")"

    if [[ ! -z "$track" ]]; then
        echo "Setting \"$track\" track number in $fileName"
        kid3-cli -c "set track '$track'" "$filePath"
    fi
    
    if [[ ! -z "$artist" ]]; then
        echo "Setting \"$artist\" artist in $fileName"
        kid3-cli -c "set artist '$artist'" "$filePath"
    fi
    
    if [[ ! -z "$album" ]]; then
        echo "Setting \"$album\" album in $fileName"
        kid3-cli -c "set album '$album'" "$filePath"
    fi

    if [[ ! -z "$year" ]]; then
        echo "Setting $year year in $fileName"
        kid3-cli -c "set date '$year'" "$filePath"
    fi

    if [[ ! -z "$genre" ]]; then
        echo "Setting $genre genre in $fileName"
        kid3-cli -c "set genre '$genre'" "$filePath"
    fi

    id3v2 --list "$filePath"
    echo
}

if [[ "$#" -eq 1 && ("$1" = "-h" || "$1" = "--help") ]]; then
    printHelp
    exit
elif [[ "$1" = "-v" || "$1" = "--version" ]]; then
    echo "$VERSION"
    exit
fi

if [[ "$#" -lt 3 ]]; then
    echo "Invalid arguments."
    echo
    printHelp
fi

while getopts t:a:l:y:g:u: option; do
    case "${option}" in
        t) track=${OPTARG} ;;
        a) artist=${OPTARG} ;;
        l) album=${OPTARG} ;;
        y) year=${OPTARG} ;;
        g) genre=${OPTARG} ;;
        u) url=${OPTARG} ;;
    esac
done

input="${@: -1}"
input="$(realpath "$input")"

if [[ -d "$input" ]]; then
    for fileName in $(ls "$input"); do
        filePath="$input/$fileName"
        setMetadata "$track" "$artist" "$album" "$year" "$genre" "$filePath"
    done
else
    setMetadata "$track" "$artist" "$album" "$year" "$genre" "$input"
fi
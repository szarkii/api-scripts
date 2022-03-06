#!/bin/bash

VERSION="1.2.0"
IFS=$'\n'

function printHelp() {
    echo "Sets metadata for music files. Downloads the file if input is URL."
    echo "Dependencies: kid3-cli, youtube-dl"
    echo "$(basename $0) [-o output] [-t track] [-n name] [-a artist] [-l album] [-y year] [-g genre] input"
    echo "  input  file, directory or URL"
    echo "     -n  will be also the name of file if input is URL (if empty the title will be used)"
    echo "     -o  output directory (if downloading file)"
    exit
}

if [[ "$#" -eq 1 && ("$1" = "-h" || "$1" = "--help") ]]; then
    printHelp
    exit
elif [[ "$1" = "-v" || "$1" = "--version" ]]; then
    echo "$VERSION"
    exit
fi

if [[ "$#" -lt 1 ]]; then
    echo "Invalid arguments."
    echo
    printHelp
fi

function downloadFile() {
    name="$1"
    output="$2"
    url="$3"

    youtube-dl -f "bestaudio/best" -ciw -o "$output/$name.%(ext)s" --extract-audio --audio-quality 0 "$url"
}

function getFileName {
    youtube-dl -o "%(title)s" --get-filename "$1"
}

function setMetadata() {
    track="$1"
    name="$2"
    artist="$3"
    album="$4"
    year="$5"
    genre="$6"
    filePath="$7"
    
    setMetadataIfNeeded "track" "$track" "$filePath"
    setMetadataIfNeeded "title" "${name//\.mp3/}" "$filePath"
    setMetadataIfNeeded "artist" "$artist" "$filePath"
    setMetadataIfNeeded "album" "$album" "$filePath"
    setMetadataIfNeeded "date" "$year" "$filePath"
    setMetadataIfNeeded "genre" "$genre" "$filePath"

    kid3-cli -c "get" "$filePath"
    echo
}

function setMetadataIfNeeded() {
    metadataName="$1"
    metadataValue="$2"
    filePath="$3"
    fileName="$(basename "$filePath")"
    
    if [[ ! -z "$metadataValue" ]]; then
        echo "Setting $metadataValue $metadataName in $fileName"
        kid3-cli -c "set $metadataName '$metadataValue'" "$filePath"
    fi
}

function deleteMetadata() {
    metadataToDelete=("$@")
    ((lastIndex=${#metadataToDelete[@]} - 1))
    filePath=${metadataToDelete[lastIndex]}
    unset metadataToDelete[lastIndex]

    for metadata in "${metadataToDelete[@]}"; do
        kid3-cli -c "remove $metadata" "$filePath"
    done
}

metadataToDelete=()

while getopts o:t:n:a:l:y:g:u:d: option; do
    case "${option}" in
        o) output=${OPTARG} ;;
        t) track=${OPTARG} ;;
        n) name=${OPTARG} ;;
        a) artist=${OPTARG} ;;
        l) album=${OPTARG} ;;
        y) year=${OPTARG} ;;
        g) genre=${OPTARG} ;;
        u) url=${OPTARG} ;;
        d)  echo "[WARN] Deleting metadata could not work properly."
            if [[ ${OPTARG} = "year" ]]; then
                metadataToDelete+=("date")
            else
                metadataToDelete+=(${OPTARG})
            fi
            ;;
    esac
done

input="${@: -1}"

# Download the file
if [[ "$input" = "http"* ]]; then
    if [[ -z "$name" ]]; then
        name=$(getFileName "$input")
    fi

    if [[ -z "$output" ]]; then
        output="."
    fi
    
    downloadFile "$name" "$output" "$input"

    input=$(ls "$output/$name"* | head -n1)
fi

# Add or delete file's metadata
input="$(realpath "$input")"

if [[ -d "$input" ]]; then
    for fileName in $(ls "$input"); do
        filePath="$input/$fileName"
        deleteMetadata "${metadataToDelete[@]}" "$filePath"
        setMetadata "$track" "$name" "$artist" "$album" "$year" "$genre" "$filePath"
    done
else
    deleteMetadata "${metadataToDelete[@]}" "$input"
    setMetadata "$track" "$name" "$artist" "$album" "$year" "$genre" "$input"
fi
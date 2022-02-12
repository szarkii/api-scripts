#!/bin/bash

VERSION="0.2.0"
IFS=$'\n'

function printHelp() {
    echo "Sets metadata for music files. Downloads the file if URL is provided."
    echo "Dependencies: kid3-cli"
    echo "$(basename $0) [-t track] [-n name] [-a artist] [-l album] [-y year] [-g genre] [-u URL] input"
    echo "  input  file or directory (N/A for -u)"
    exit
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

# TODO
function downloadFile() {
    youtube-dl --prefer-ffmpeg --format "bestaudio/best" --extract-audio --audio-quality 0 --audio-format mp3 --output "$DIR/$name.%(ext)s" "$url"
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
    setMetadataIfNeeded "title" "$name" "$filePath"
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

while getopts t:n:a:l:y:g:u:d: option; do
    case "${option}" in
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
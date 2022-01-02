#!/bin/bash

VERSION="0.1.1"

WIDTH="1920"
HEIGHT="1080"
DURATION_SECONDS="60"
OUTPUT_DIR="$HOME/cam/out"
SPACE_LIMIT_MB="30000"
EXTENSION="h264"

function printHelp() {
    echo "$(basename $0) [options]"
    echo "  -w  width (default $WIDTH)"
    echo "  -h  height (default $HEIGHT)"
    echo "  -t  one clip duration in seconds (default $DURATION_SECONDS)"
    echo "  -o  output directory (default $OUTPUT_DIR)"
    echo "  -l  space limit in MB (default $SPACE_LIMIT_MB)"
    exit
}

function rec() {
    milliseconds=$(($DURATION_SECONDS * 1000))
    time="$(date -Iseconds)"
    filename="${time//:/_}"
    filename="${filename/+/-}"
    path="$OUTPUT_DIR/$filename.$EXTENSION"
    os=$(cat /etc/os-release | grep 'VERSION_CODENAME' | tr -d 'VERSION_CODENAME=')

    if [[ "$os" = 'bullseye' ]]; then
        libcamera-vid -o "$path" -t "$milliseconds" --width "$WIDTH" --height "$HEIGHT"
    else
        raspivid -o "$path" -t "$milliseconds" --width "$WIDTH" --height "$HEIGHT"
    fi
}

function spaceLimitReached() {
    spaceTaken=$(du $OUTPUT_DIR | cut -f1)
    if [[ $spaceTaken -gt $(($SPACE_LIMIT_MB * 1000)) ]]; then
        echo "true"
    else
        echo "false"
    fi
}

if [[ "$#" -eq 1 && ("$1" = "-h" || "$1" = "--help") ]]; then
    printHelp
    exit
elif [[ "$1" = "-v" || "$1" = "--version" ]]; then
    echo "$VERSION"
    exit
fi

while getopts w:h:t:o:l: option; do 
    case "${option}" in
        w) WIDTH=${OPTARG} ;;
        h) HEIGHT=${OPTARG} ;;
        t) DURATION_SECONDS=${OPTARG} ;;
        o) OUTPUT_DIR=${OPTARG} ;;
        l) SPACE_LIMIT_MB=${OPTARG} ;;
    esac
done

mkdir -p $OUTPUT_DIR

while [[ $(spaceLimitReached) = "false" ]]; do
    rec
done

echo "Limit reached."
exit
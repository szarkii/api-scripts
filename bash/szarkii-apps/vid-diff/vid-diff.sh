#!/bin/bash

VERSION="0.1.2"
FRAMES_TO_CHECK_NUMBER=5
SIMILARITY_THRESHOLD=20

APP_DIR="$HOME/szarkii-apps/$(basename $0)"
SAME_VIDEOS_DIR="$APP_DIR/same"
DIFFERENT_VIDEOS_DIR="$APP_DIR/different"
PROCESSED_VIDEOS_DIR="$APP_DIR/processed"
TMP_REFERENCE_FILE_PATH="/tmp/$(basename $0)-img-$RANDOM.jpg"

function showError() {
    echo "$1"
    printHelp
    exit
}

function printHelp() {
    echo "Checks that the video shows static content that does not change over the course of the video."
    echo "The script creates a snapshot of a frame every second. If the video has differences between a first and any other snapshots, all snapshots will be moved to $DIFFERENT_VIDEOS_DIR directory. Otherwise to $SAME_VIDEOS_DIR."
    echo "Increasing the similarity threshold and the number of frames to be checked increases the accuracy and time of script execution."
    echo
    echo "$(basename $0) [-s threshold] [-n frames] input"
    echo "  input  video or directory name"
    echo "     -s  similarity threshold ($SIMILARITY_THRESHOLD by default)"
    echo "     -n  number of frames in equal intervals to compare ($FRAMES_TO_CHECK_NUMBER by default)"
    exit
}

function checkDifference() {
    videoPath="$1"
    videoFileName=$(basename "$videoPath")
    framesDirName="${videoFileName%.*}"
    framesDirPath="$PROCESSED_VIDEOS_DIR/$framesDirName"

    if [[ -d "$framesDirPath" ]]; then
        echo "$videoFileName was processed before - omitting."
        return 1
    fi

    mkdir -p "$framesDirPath"
    cd "$framesDirPath"
    ffmpeg -i "$videoPath" -r 1 -f image2 image-%3d.jpeg 1>/dev/null 2>/dev/null

    referenceFrame="image-001.jpeg"
    allFramesNumber=$(ls "$framesDirPath" | wc -l)
    framesInterval=$(($allFramesNumber / $FRAMES_TO_CHECK_NUMBER))
    framesIndexesInSedFormat=""

    for (( i = "$framesInterval"; i < "$allFramesNumber"; i += "$framesInterval" )); do
        framesIndexesInSedFormat+="${i}p;"
    done

    differenceFound="false"
    for fileToCompare in $(ls "$framesDirPath" | sed -n "$framesIndexesInSedFormat"); do
        similarityIndex=$(szarkii-img-diff "$framesDirPath/$referenceFrame" "$framesDirPath/$fileToCompare")
        
        if (( $(echo "$similarityIndex < $SIMILARITY_THRESHOLD" | bc -l) )); then
            differenceFound="true"
            break
        fi
    done

    if [[ "$differenceFound" = "true" ]]; then
        echo "Found difference in $videoFileName."
        mkdir -p "$DIFFERENT_VIDEOS_DIR/$framesDirName"
        mv "$framesDirPath/"* "$DIFFERENT_VIDEOS_DIR/$framesDirName"
    else
        echo "No difference in $videoFileName."
        mkdir -p "$SAME_VIDEOS_DIR/$framesDirName"
        mv "$framesDirPath/"* "$SAME_VIDEOS_DIR/$framesDirName"
    fi
}

if [[ "$#" -eq 1 && ("$1" = "-h" || "$1" = "--help") ]]; then
    printHelp
    exit
elif [[ "$1" = "-v" || "$1" = "--version" ]]; then
    echo "$VERSION"
    exit
fi

while getopts s:n: option; do 
    case "${option}" in
        s) SIMILARITY_THRESHOLD=${OPTARG} ;;
        n) FRAMES_TO_CHECK_NUMBER=${OPTARG} ;;
    esac
done

input="${@: -1}"
input=$(realpath "$input")

[[ -z "$input" ]] && showError "Input is required."
[[ "$FRAMES_TO_CHECK_NUMBER" -lt 2 ]] && showError "The number of frames must be at least 2."

mkdir -p "$SAME_VIDEOS_DIR"
mkdir -p "$DIFFERENT_VIDEOS_DIR"
mkdir -p "$PROCESSED_VIDEOS_DIR"

if [[ -d "$input" ]]; then
    for fileName in $(ls "$input"); do
        checkDifference "$input/$fileName"
    done
else
    checkDifference "$input"
fi
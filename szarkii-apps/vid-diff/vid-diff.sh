#!/bin/bash

VERSION="1.0.1"
FRAMES_TO_CHECK_PERCENTAGE=50
SIMILARITY_THRESHOLD=20

APP_DIR="$SZARKII_APPS_DIR/$(basename $0)"
DIFFERENT_VIDEOS_DIR="$APP_DIR/different"
FRAMES_DIR="$APP_DIR/frames"

HELP="
Checks that the video shows static content that does not change over the course of the video.
The script creates a snapshot of a frame every second. If the video has differences between a first and any other snapshots, all snapshots will be moved to $DIFFERENT_VIDEOS_DIR directory. Otherwise to $SAME_VIDEOS_DIR.
Increasing the similarity threshold and the percentage of frames to be checked increases the accuracy and time of script execution.

$(basename $0) [-s threshold] [-n frames] video [video2, video3, ...]
    video  path to the video file
    -s     similarity threshold ($SIMILARITY_THRESHOLD by default)
    -n     [DOES NOT WORK YET!] percentage of frames in equal intervals to compare ($FRAMES_TO_CHECK_PERCENTAGE by default)
"

function generateFrames() {
    framesDir="$1"
    videoPath="$2"
    mkdir -p $framesDir
    cd $framesDir
    ffmpeg -i "$videoPath" -r 1 -f image2 image-%3d.jpeg 1>/dev/null 2>/dev/null
    cd -
}

function checkDifference() {
    framesDir="$1"
    videoName="$2"

    referenceFrame=$(ls -tr "$framesDir" | head -n1)

    for currentFramePath in "$framesDir"/*; do
        currentFrame=$(basename $currentFramePath)

        if [[ "$currentFrame" = "$referenceFrame" ]]; then
            continue
        fi

        outputFilePath="$DIFFERENT_VIDEOS_DIR/${videoName}_$currentFrame"
        areFramesDifferent=$(szarkii-img-diff -s "$SIMILARITY_THRESHOLD" -o "$outputFilePath" "$framesDir/$referenceFrame" "$framesDir/$currentFrame")

        if [[ "$areFramesDifferent" = "True" ]]; then
            lib_logInfo "The frames in '$videoName' video are different. The difference is saved under '$outputFilePath'."
            break
        fi
    done

    if [[ "$areFramesDifferent" = "False" ]]; then
        lib_logInfo "The frames in '$videoName' video are the same."
    fi
}

source "$SZARKII_APPS_LIB_DIR/arguments.sh"
source "$SZARKII_APPS_LIB_DIR/log.sh"

lib_printHelpOrVersionIfRequested "$@"
requiredArgumentsNumber=1

while getopts s:n: option; do 
    case "${option}" in
        s)
            SIMILARITY_THRESHOLD=${OPTARG}
            requiredArgumentsNumber=$((requiredArgumentsNumber += 2))
            ;;
        n) 
            if [[ ${OPTARG} -lt 2 ]]; then
                lib_logError "The number of frames must be at least 2."
                exit 1
            fi
            FRAMES_TO_CHECK_NUMBER=${OPTARG}
            requiredArgumentsNumber=$((requiredArgumentsNumber += 2))
            ;;
    esac
done

if [[ $# -lt requiredArgumentsNumber ]]; then
    lib_logError "Not enough arguments."
    echo -e $HELP
    exit 1
fi

mkdir -p "$FRAMES_DIR"
mkdir -p "$DIFFERENT_VIDEOS_DIR"

for file in ${@:$requiredArgumentsNumber}; do
    filePath=$(realpath "$file")

    if [[ ! -f "$filePath" ]]; then
        lib_logError "File '$filePath' does not exist."
        continue
    fi

    fileName=$(basename "$file")
    fileNameWithoutExtension=${fileName%.*}
    framesDir="$FRAMES_DIR/$fileNameWithoutExtension"

    if [[ -d "$framesDir" ]]; then
        lib_logInfo "Frames directory for '$fileName' video already exist. Frames generation skipped."
    else
        lib_logInfo "Generating frames for '$fileName' video."
        generateFrames "$framesDir" "$filePath"
    fi

    checkDifference "$framesDir" "$fileNameWithoutExtension"
done

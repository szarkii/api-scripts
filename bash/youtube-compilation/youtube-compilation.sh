#!/bin/bash

INPUT_PATH='input.txt'
YOUTUBE_URL=''
ARTIST=''
ALBUM=''
GENRE=''

function getLinesNumber() {
    filePath="$1"
    grep -v '^$' "$filePath" | wc -l
}

function getLine() {
    filePath="$1"
    lineNumber="$2"
    grep -v '^$' "$filePath" | head -n "$lineNumber" | tail -n1
}

function getStartTime() {
    line="$1"
    echo "$line" | cut '-d ' -f1
}

function getTitle() {
    line="$1"
    echo "$line" | cut '-d ' -f2- | sed -e 's|/|, |g'
}

music-metadata "$YOUTUBE_URL"
albumFileName=$(ls -t | head -n1)
albumName=${albumFileName%.*}

mkdir "$albumName"

allTracksNumber=$(getLinesNumber "$INPUT_PATH")

for (( i=1; i<"$allTracksNumber"; i++ )); do
    line=$(getLine "$INPUT_PATH" "$i")
    nextLine=$(getLine "$INPUT_PATH" $(($i+1)))
    
    trackNumber="$i"
    startTime=$(getStartTime "$line")
    endTime=$(getStartTime "$nextLine")
    title=$(getTitle "$line")
    filePath="$albumName/$title.mp3"

    ffmpeg -i "$albumFileName" -ss "$startTime" -to "$endTime" "$filePath"
    music-metadata -t "$trackNumber" -n "$title" -a "$ARTIST" -l "$ALBUM" -g "$GENRE" "$filePath"
done

lastLine=$(getLine "$INPUT_PATH" "$allTracksNumber")
trackNumber="$allTracksNumber"
startTime=$(getStartTime "$lastLine")
title=$(getTitle "$lastLine")
filePath="$albumName/$title.mp3"

ffmpeg -i "$albumFileName" -ss "$startTime" "$albumName/$title.mp3"
music-metadata -t "$trackNumber" -n "$title" -a "$ARTIST" -l "$ALBUM" -g "$GENRE" "$filePath"

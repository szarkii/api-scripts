#!/bin/bash

VERSION="0.1.0"
BIN_DIR="/usr/local/bin"
REPOSITORY_URL="https://raw.githubusercontent.com/rkowalik/api-scripts/szarkii-apps/bash/szarkii-apps"
APPS_URL="$REPOSITORY_URL/apps"

APPS=$(curl -s $APPS_URL)

function assertScriptNameProvided() {
    if [[ "$1" = "" ]]; then
        echo "You have to provide a script name. Available scripts:"
        echo "$APPS" | cut -d ":" -f1 | sed 's/\(.*\)/ \* \1/'
        exit
    fi
}

function getScript() {
    scriptName="$1"
    relativePath=$(echo "$APPS" | grep "$scriptName" | cut -d ":" -f2)
    curl -s "$REPOSITORY_URL/$relativePath"
}

if [[ "$1" = "-v" || "$1" = "--version" ]]; then
    echo "$VERSION"
elif [[ "$1" = "-i" || "$1" = "--install" ]]; then
    scriptName="$2"
    assertScriptNameProvided "$scriptName"
    
    scriptPath="$BIN_DIR/$scriptName"
    getScript "$scriptName" > "$scriptPath" || exit
    chmod +x "$scriptPath" || exit

    echo "$scriptName app installed."
elif [[ "$1" = "-u" || "$1" = "--update" ]]; then
    assertScriptNameProvided "$2"
fi
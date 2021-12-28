#!/bin/bash

VERSION="0.1.0"
BIN_DIR="/usr/local/bin"
REPOSITORY_URL="https://raw.githubusercontent.com/rkowalik/api-scripts/szarkii-apps/bash/szarkii-apps"
APPS_URL="$REPOSITORY_URL/apps"

APPS=$(curl -s $APPS_URL)

function updateApps() {
    for appDetails in "$APPS"; do
        app=$(echo "$appDetails" | cut -d ':' -f1)
        currentVersion=$($app -v)
        latestVersion=$(echo "$appDetails" | cut -d ':' -f3)

        if [[ $(which $app) != "" && $currentVersion != $latestVersion ]]; then
            echo "$app $currentVersion requires update to $latestVersion version."
            installApp "$app"
        else
            echo "$app $currentVersion has the latest version."
        fi
    done
}

function installApp() {
    appName="$1"
    assertAppNameProvided "$appName"
    
    appPath="$BIN_DIR/$appName"
    getAppScript "$appName" > "$appPath" || exit
    chmod +x "$appPath" || exit

    echo "$appName $(getLatestAppVersion) app installed."
}

function assertAppNameProvided() {
    if [[ "$1" = "" ]]; then
        echo "You have to provide an app name."
        printAvailableApps
        exit
    fi
}

function printAvailableApps() {
    echo "Available apps:"
    echo "$APPS" | cut -d ':' -f1 | sed 's/\(.*\)/ \* \1/'
}

function getAppScript() {
    appName="$1"
    relativePath=$(echo "$APPS" | grep "$appName" | cut -d ':' -f2)
    curl -s "$REPOSITORY_URL/$relativePath"
}

function getLatestAppVersion() {
    appName="$1"
    echo "$APPS" | grep "$appName" | cut -d ':' -f3
}


if [[ "$1" = "-a" || "$1" = "--apps" ]]; then
    printAvailableApps
    exit
elif [[ "$1" = "-i" || "$1" = "--install" ]]; then
    installApp "$2"
elif [[ "$1" = "-u" || "$1" = "--update" ]]; then
    updateApps
fi
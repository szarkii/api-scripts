#!/bin/bash

VERSION="0.2.1"
BIN_DIR="/usr/local/bin"
REPOSITORY_URL="https://raw.githubusercontent.com/rkowalik/api-scripts/szarkii-apps/bash/szarkii-apps"
APPS_URL="$REPOSITORY_URL/apps"

mapfile -t APPS < <( curl -s "$APPS_URL" )

function printHelp() {
    echo "$(basename $0) [-a | --apps] [-i | --install name] [-u | --update]  [-r | --remove name]"
    echo "  -a --apps  print all apps"
    echo "  -i --install  install app"
    echo "  -u --update update all apps"
    echo "  -r --remove app"
    exit
}

function updateApps() {
    for appDetails in $(getAllAppsDetails); do
        app=$(getAppNameFromAppDetails "$appDetails")

        if [[ -z $(which $app) ]]; then
            continue
        fi

        currentVersion=$($app -v)
        latestVersion=$(getAppVersionFromAppDetails "$appDetails")

        if [[ $currentVersion != $latestVersion ]]; then
            echo " * $app $currentVersion requires update to $latestVersion version."
            installApp "$app"
        else
            echo " * $app $currentVersion has the latest version."
        fi
    done
}

function installApp() {
    appName="$1"
    assertAppNameProvided "$appName"
    
    appPath="$BIN_DIR/$appName"
    getAppScript "$appName" > "$appPath" || exit
    chmod +x "$appPath" || exit

    echo "$appName $($appName -v) app installed."
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
    
    for appDetails in $(getAllAppsDetails); do
        name=$(getAppNameFromAppDetails "$appDetails")
        version=$(getAppVersionFromAppDetails "$appDetails")
        echo " * $name ($version)"
    done
}

function getAppNameFromAppDetails() {
    appDetails="$1"
    echo "$appDetails" | cut -d ':' -f1
}

function getAppScript() {
    appName="$1"
    relativePath=$(getAppDetails "$appName" | cut -d ':' -f2)
    curl -s "$REPOSITORY_URL/$relativePath"
}

function getLatestAppVersion() {
    appName="$1"
    appDetails=$(getAppDetails "$appName")
    getAppVersionFromAppDetails "$appDetails"
}

function getAppVersionFromAppDetails() {
    appDetails="$1"
    echo "$appDetails" | cut -d ':' -f3
}

function getAllAppsDetails() {
    getAppDetails ""
}

function getAppDetails() {
    appName="$1"
    for appDetails in "${APPS[@]}"; do
        if [[ "$appDetails" = *"$appName"* ]]; then
            echo $appDetails
        fi
    done
}

function removeApp() {
    appName="$1"
    assertAppNameProvided "$appName"
    if [[ -z $(which $appName) ]]; then
        echo "$appName is not installed."
    fi

    rm "$BIN_DIR/$appName" || exit
    if [[ -z $(which $appName) ]]; then
        echo "$appName has been removed."
    else
        echo "Removing the application failed. Do you have enough privileges?"
    fi
}

if [[ "$#" -eq 1 && ("$1" = "-h" || "$1" = "--help") ]]; then
    printHelp
    exit
elif [[ "$1" = "-v" || "$1" = "--version" ]]; then
    echo "$VERSION"
    exit
fi

if [[ "$1" = "-a" || "$1" = "--apps" ]]; then
    printAvailableApps
    exit
elif [[ "$1" = "-i" || "$1" = "--install" ]]; then
    installApp "$2"
elif [[ "$1" = "-u" || "$1" = "--update" ]]; then
    updateApps
elif [[ "$1" = "-r" || "$1" = "--remove" ]]; then
    removeApp "$2"
fi
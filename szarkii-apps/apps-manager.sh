#!/bin/bash

VERSION="0.4.0"
BIN_DIR="/usr/local/bin"
REPOSITORY_URL="https://raw.githubusercontent.com/rkowalik/api-scripts/szarkii-apps/szarkii-apps"
APPS_URL="$REPOSITORY_URL/apps"
LIBS_URL="$REPOSITORY_URL/lib"

APPS_ROOT_DIR="/home/$USER/szarkii-apps"
LIBRARIES_DIR="$APPS_ROOT_DIR/.lib"
VARIABLES_FILE_PATH="$LIBRARIES_DIR/variables.sh"

HELP="
$(basename $0) [-a | --apps] [-i | --install name] [-u | --update]  [-d | --delete name]
  -a --apps     print all apps
  -i --install  install app
  -u --update   update all apps
  -d --delete   delete app
" 

mapfile -t APPS < <( curl -s "$APPS_URL" )

function updateApps() {
    updateLibraries

    echo "Updating apps:"
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

    echo "All apps checked."
    echo
}

function updateLibraries() {
    echo "Updating the libraries."

    for libraryFile in $(curl -s "$LIBS_URL/list"); do
        library="${libraryFile%.*}"
        echo "Updating the $library library."
        wget -q "$LIBS_URL/$libraryFile" -O "$LIBRARIES_DIR/$libraryFile" || exit
        echo "The $library library updated."
    done

    echo "All libraries updated."
    echo
}

function installApp() {
    appName="$1"
    assertAppNameProvided "$appName"
    
    appPath="$BIN_DIR/$appName"
    getAppScript "$appName" > "/tmp/$appName"
    sudo mv "/tmp/$appName" "$appPath" || exit
    sudo chmod +x "$appPath" || exit

    updateLibraries
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

function deleteApp() {
    appName="$1"
    assertAppNameProvided "$appName"
    if [[ -z $(which $appName) ]]; then
        echo "$appName is not installed."
    fi

    sudo rm "$BIN_DIR/$appName" || exit
    if [[ -z $(which $appName) ]]; then
        echo "$appName has been deleted."
    else
        echo "Deleting the application failed. Do you have enough privileges?"
    fi
}

mkdir -p "$LIBRARIES_DIR"

if [[ "$#" -eq 1 && ("$1" = "-h" || "$1" = "--help") ]]; then
    echo -e "$HELP"
    exit
elif [[ "$1" = "-v" || "$1" = "--version" ]]; then
    echo "$VERSION"
    exit
elif [[ "$1" = "--get-apps-root-dir" ]]; then
    echo $APPS_ROOT_DIR
    exit
elif [[ "$1" = "--get-apps-lib-dir" ]]; then
    echo $LIBRARIES_DIR
    exit
elif [[ "$1" = "--get-variables-path" ]]; then
    echo $VARIABLES_FILE_PATH
    exit
fi

if [[ "$1" = "-a" || "$1" = "--apps" ]]; then
    printAvailableApps
    exit
elif [[ "$1" = "-i" || "$1" = "--install" ]]; then
    installApp "$2"
elif [[ "$1" = "-u" || "$1" = "--update" ]]; then
    updateApps
elif [[ "$1" = "-d" || "$1" = "--delete" ]]; then
    deleteApp "$2"
fi
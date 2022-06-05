#!/bin/bash

VERSION="0.3.0"
BIN_DIR="/usr/local/bin"
REPOSITORY_URL="https://raw.githubusercontent.com/rkowalik/api-scripts/szarkii-apps/szarkii-apps"
APPS_URL="$REPOSITORY_URL/apps"
LIBS_URL="$REPOSITORY_URL/lib"

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

    lib_logInfo "Updating apps:"
    for appDetails in $(getAllAppsDetails); do
        app=$(getAppNameFromAppDetails "$appDetails")

        if [[ -z $(which $app) ]]; then
            continue
        fi

        currentVersion=$($app -v)
        latestVersion=$(getAppVersionFromAppDetails "$appDetails")

        if [[ $currentVersion != $latestVersion ]]; then
            lib_logWarn " * $app $currentVersion requires update to $latestVersion version."
            installApp "$app"
        else
            lib_logInfo " * $app $currentVersion has the latest version."
        fi
    done

    lib_logSuccess "All apps checked."
    lib_logSeparator
}

function updateLibraries() {
    lib_logInfo "Updating the libraries."

    for libraryFile in $(curl -s "$LIBS_URL/list"); do
        library="${libraryFile%.*}"
        lib_logInfo "Updating the $library library."
        wget -q "$LIBS_URL/$libraryFile" -O "$SZARKII_APPS_LIB_DIR/$libraryFile" || exit
        lib_logSuccess "The $library library updated."
    done

    lib_logSuccess "All libraries updated."
    lib_logSeparator
}

function installApp() {
    appName="$1"
    assertAppNameProvided "$appName"
    
    appPath="$BIN_DIR/$appName"
    getAppScript "$appName" > "$appPath" || exit
    chmod +x "$appPath" || exit

    lib_logSuccess "$appName $($appName -v) app installed."
}

function assertAppNameProvided() {
    if [[ "$1" = "" ]]; then
        lib_logError "You have to provide an app name."
        printAvailableApps
        exit
    fi
}

function printAvailableApps() {
    lib_logInfo "Available apps:"
    
    for appDetails in $(getAllAppsDetails); do
        name=$(getAppNameFromAppDetails "$appDetails")
        version=$(getAppVersionFromAppDetails "$appDetails")
        lib_logInfo " * $name ($version)"
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
        lib_logError "$appName is not installed."
    fi

    rm "$BIN_DIR/$appName" || exit
    if [[ -z $(which $appName) ]]; then
        lib_logSuccess "$appName has been deleted."
    else
        lib_logError "Deleting the application failed. Do you have enough privileges?"
    fi
}

if [[ -z "$SZARKII_APPS_DIR" || -z "$SZARKII_APPS_LIB_DIR" ]]; then
    echo "Installing the necessary variables."

    SZARKII_APPS_DIR="/home/$USER/szarkii-apps"
    SZARKII_APPS_LIB_DIR="$SZARKII_APPS_DIR/.lib"

    mkdir -p "$SZARKII_APPS_LIB_DIR"

    echo >> ~/.bashrc
    echo "# SZARKII_APPS necessary variables" >> ~/.bashrc
    echo "export SZARKII_APPS_DIR=\"$SZARKII_APPS_DIR\"" >> ~/.bashrc
    echo "export SZARKII_APPS_LIB_DIR=\"$SZARKII_APPS_LIB_DIR\"" >> ~/.bashrc

    echo
    echo "SZARKII_APPS_DIR: $SZARKII_APPS_DIR"
    echo "SZARKII_APPS_LIB_DIR: $SZARKII_APPS_LIB_DIR"
    echo "Variables setup. You can change them $(realpath ~/.bashrc) file."

    updateLibraries

    echo "Please restart your console."
    exit
fi

source "$SZARKII_APPS_LIB_DIR/arguments.sh"
source "$SZARKII_APPS_LIB_DIR/log.sh"

lib_printHelpOrVersionIfRequested "$@"

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
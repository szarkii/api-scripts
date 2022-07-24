#!/bin/bash

source $(szarkii-apps --get-variables-path)
source $LIB_HELP

VERSION="0.0.1"

CONFIG_FILE_PATH="$SZARKII_APPS_CONFIG_DIR/notifier.conf"
KEY_CONFIG_NAME="key"
CHANNEL_CONFIG_NAME="channel"

HELP="Sends a message via Telegram bot.

$(basename $0) [-k key] [-c channel] [message]
    -k  set telegram API key for the bot, attached to channel, e.g. 1234567890:AAAAxY6udNO5u-9fO793yFdZaL1qU2RIkGT
    -c  set telegram channel name to which message will be send, e.g. blogposteideas
"

function setConfigValue {
    key="$1"
    value="$2"
    sed -i "$CONFIG_FILE_PATH" -e "s/$key.*/$key:$value/"
}

function getConfigValue {
    key="$1"
    grep "$CONFIG_FILE_PATH" -e "$key" | cut -d: -f2-
}

lib_printHelpOrVersionIfRequested "$@"
[[ $# -lt 1 ]] && lib_printHelpAndExit "Not enough arguments."

if [[ ! -f "$CONFIG_FILE_PATH" ]]; then
    echo "$KEY_CONFIG_NAME:" > "$CONFIG_FILE_PATH"
    echo "$CHANNEL_CONFIG_NAME:" >> "$CONFIG_FILE_PATH"
fi

sendMessage=true
while getopts k:c: option; do
    case "${option}" in
        k)
            setConfigValue "$KEY_CONFIG_NAME" "${OPTARG}"
            sendMessage=false
            ;;
        c)
            setConfigValue "$CHANNEL_CONFIG_NAME" "${OPTARG}"
            sendMessage=false
            ;;
    esac
done

if [[ $sendMessage = "false" ]]; then
    exit
fi

key=$(getConfigValue "$KEY_CONFIG_NAME")
channel=$(getConfigValue "$CHANNEL_CONFIG_NAME")
message="$1"

[[ -z "$key" || -z "$channel" ]] && lib_printHelpAndExit "Please set API key and channel name."

url="https://api.telegram.org/bot${key}/sendMessage?chat_id=${channel}&text=${message}"
curl "$url"
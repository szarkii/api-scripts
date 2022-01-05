#!/bin/bash

VERSION="0.4.0"
WIDTH=1024
HEIGHT=768
PORT=11002

RASPBIAN_OS_CODE=$(cat /etc/os-release | grep 'VERSION_CODENAME' | tr -d 'VERSION_CODENAME=')

if [[ "$#" -eq 1 && ("$1" = "-h" || "$1" = "--help") ]]; then
    echo "$(basename $0) [-w width] [-h height] [-p port] [-v | --version]"
    echo "  -w  width ($WIDTH by default)"
    echo "  -h  height ($HEIGHT by default)"
    echo "  -p  port ($PORT by default)"
    echo "  -v  version"
    exit
fi

if [[ "$1" = "-v" || "$1" = "--version" ]]; then
    echo "$VERSION"
    exit
fi

while getopts w:h:p: option; do 
    case "${option}" in
        w) WIDTH=${OPTARG} ;;
        h) HEIGHT=${OPTARG} ;;
        p) PORT=${OPTARG} ;;
    esac
done

if [[ "$RASPBIAN_OS_CODE" = "bullseye" ]]; then
    libcamera-vid -t 0 --width "$WIDTH" --height "$HEIGHT" --inline --listen -o "tcp://0.0.0.0:$PORT"
else
    raspivid -o - -t 0 -w "$WIDTH" -h "$HEIGHT" -fps 24 | \
        cvlc -vvv stream:///dev/stdin --sout "#standard{access=http,mux=ts,dst=:$PORT}" :demux=h264
fi
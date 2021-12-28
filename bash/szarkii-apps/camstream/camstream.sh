#!/bin/bash

VERSION="0.2.0"
WIDTH=1024
HEIGHT=768
PORT=11002

if [[ "$1" = "-h" || "$1" = "--help" ]]; then
    echo "$0 [-w width] [-h height] [-p port]"
    echo "  -w  width ($WIDTH by default)"
    echo "  -h  height  ($HEIGHT by default)"
    echo "  -p  port  ($PORT by default)"
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

raspivid -o - -t 0 -w "$WIDTH" -h "$HEIGHT" -fps 24 | \
    cvlc -vvv stream:///dev/stdin --sout "#standard{access=http,mux=ts,dst=:$PORT}" :demux=h264
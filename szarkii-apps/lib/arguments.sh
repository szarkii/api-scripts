
function lib_printHelpOrVersionIfRequested {
    if [[ "$#" -eq 1 && ("$1" = "-h" || "$1" = "--help") ]]; then
        echo "$HELP"
        exit
    elif [[ "$1" = "-v" || "$1" = "--version" ]]; then
        echo "$VERSION"
        exit
    fi
}
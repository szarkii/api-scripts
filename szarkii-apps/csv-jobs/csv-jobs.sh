VERSION="0.1.0"
IFS=$'\n'
SEPARATOR=","
ESCAPED_SEPARATOR="&-TEMPORARY_ESCAPED_SEPARATOR-&"
TEMPLATE_FILE_HEADER="command${SEPARATOR}file"

function printHelp() {
    echo "Helps with processing multiple files. Creates CSV file or executes commands from this file."
    echo "Command must be in the first column."
    echo "Command must not contain $ sign except for column reference."
    echo "Columns cannot contain \" sign (arguments are wrapped with \" automatically)."
    echo "$(basename $0) [-c | --create] [file]"
    echo "  -c | --create  creates CSV template files with all files from current directory"
    echo "                 name is the same as directory"
    echo "           file  template file used to execute commands"
    exit
}

if [[ "$#" -eq 1 && ("$1" = "-h" || "$1" = "--help") ]]; then
    printHelp
    exit
elif [[ "$1" = "-v" || "$1" = "--version" ]]; then
    echo "$VERSION"
    exit
fi

if [[ "$#" -lt 1 ]]; then
    echo "Invalid arguments."
    echo
    printHelp
fi

function createTemplateFile() {
    fileName="$(basename $PWD).csv"
    echo $TEMPLATE_FILE_HEADER > "$fileName"

    for file in $(ls . | grep -v "$fileName"); do
        filePath="$(realpath "$file")"
        echo "${SEPARATOR}\"${filePath}\"" >> "$fileName"
    done

    echo "Created $(realpath $fileName)"
}

function executeCommands() {
    templatePath="$1"

    for line in $(tail -n +1 "$templatePath"); do
        command=$(getColumnValue $line 1)
        while [[ $command = *"$"* ]]; do
            columnNumber=$(echo $command | sed -e 's/.*\$//' -e 's/\([1-9]\).*/\1/')
            columnValue=$(getColumnValue "$line" "$columnNumber")
            command=${command/\$$columnNumber/\"$columnValue\"}
        done
        echo $command
        bash -c $command
        echo
    done
}

function getColumnValue() {
    csvLine="$1"
    csvColumnNumber="$2"
    
    while [[ "$csvLine" = *"\""* ]]; do
        columnWithSeparator=$(echo "$csvLine" | sed -e 's/.*\(".*,.*"\).*/\1/')
        escapedColumn=${columnWithSeparator//$SEPARATOR/$ESCAPED_SEPARATOR}
        escapedColumn=${escapedColumn//\"/}
        csvLine=${csvLine//$columnWithSeparator/$escapedColumn}
    done

    columnValue=$(echo "$csvLine" | cut -d "$SEPARATOR" -f "$csvColumnNumber")
    echo ${columnValue//$ESCAPED_SEPARATOR/$SEPARATOR}

}

function getFirstVariableFromCommand() {
    command="$1"
}

if [[ "$1" = "-c" || "$1" = "--create" ]]; then
    createTemplateFile
else
    executeCommands "$(realpath "$1")"
fi
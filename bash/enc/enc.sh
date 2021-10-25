#!/bin/bash

function showHelp() {
	echo "Usage:	enc [[-d | --decrypt] | [-p | --print]] file"
}

function encrypt {
	file="$1"
	openssl enc -aes-256-cbc -salt -in "$file" -out "$file.enc" \
		&& shred -zu "$file"
}

function decrypt {
	file="$1"
	openssl enc -aes-256-cbc -d -in "$file"
}

function decryptToFile {
	inputFile="$1"
	outputFile=${inputFile//.enc$/}
	openssl enc -aes-256-cbc -d -in "$inputFile" -out "$outputFile" \
		&& shred -zu "$inputFile"
}

if [[ $# -lt 1 ]]; then
	echo "Invalid arguments number."
	showHelp
	exit
fi

if [[ "$1" = "-h" || "$1" = "--help" ]]; then
	showHelp
	exit
fi

file="${@: -1}"

if [[ "$file" != */* ]]; then
	file=$(pwd)"/$file"
fi

if [[ "$1" = "-d" || "$1" = "--decrypt" ]]; then
	decryptToFile "$file"
elif [[ "$1" = "-p" || "$1" = "--print" ]]; then
	decrypt "$file"
else
	encrypt "$file"
fi

#!/usr/bin/env bash

#!#########################################################################
#!                                                                       ##
#! This script creates a powerShell script that should be used to apply  ##
#! ArchZen settings to VS Code on Windows.                               ##
#!                                                                       ##
#!#########################################################################

source archzen.sh

declare -a extensions=()
declare \
	srcfile='resources/setup-vscode.ps1.template' \
	outfile='scripts/__generated/setup-vscode.ps1' \
	template='{{ARCHZEN_EXTENSION_IDS}}' \
	value="\n"

for ext in "${__VSCODE_EXTENSIONS[@]}"; do
	extensions+=("${ext#*:}")
done

value+="$(printf "	%s\n" "${extensions[@]}")"

mkdir -p "$(dirname "$outfile")" &>/dev/null
cp "$srcfile" "$outfile" &>/dev/null
sed -i "s/$template/$value/g" "$outfile"

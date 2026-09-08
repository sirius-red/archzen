#!/usr/bin/env bash

#!#########################################################################
#!                                                                       ##
#! This script creates a powerShell script that should be used to apply  ##
#! ArchZen settings to VS Code on Windows.                               ##
#!                                                                       ##
#!#########################################################################

declare -x OS='windows'

source archzen.sh

declare srcfile='resources/templates/setup-vscode.ps1.template'
declare outfile='scripts/powershell/setup-vscode.ps1'
declare template_key='{{ARCHZEN_EXTENSION_IDS}}'
declare template_value=''
declare content=''

for ext in "${__VSCODE_EXTENSIONS[@]}"; do
	template_value+="\t'${ext#*:}'\n"
done

template_value="$(printf "%b" "$template_value")"
content="$(cat "$srcfile")"
content="${content/${template_key}/${template_value}}"

[ -f "$outfile" ] && rm -f "$outfile" &>/dev/null
mkdir -p "$(dirname "$outfile")" &>/dev/null
echo "$content" > "$outfile"

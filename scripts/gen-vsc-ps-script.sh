#!/usr/bin/env bash

#!#########################################################################
#!                                                                       ##
#! This script creates a powerShell script that should be used to apply  ##
#! ArchZen settings to VS Code on Windows.                               ##
#!                                                                       ##
#!#########################################################################

source archzen.sh

declare srcfile='resources/setup-vscode.ps1.template'
declare outfile='scripts/__generated/setup-vscode.ps1'
declare template_key='{{ARCHZEN_EXTENSION_IDS}}'
declare template_value="\n"
declare content=''

for ext in "${__VSCODE_EXTENSIONS[@]}"; do
	declare ext_id="${ext#*:}"
	template_value+="\t'${ext_id}'\n"
done

template_value="$(printf "%b" "$template_value")"
content="$(cat "$srcfile")"
content="${content/${template_key}/${template_value}}"

[ -f "$outfile" ] && rm -f "$outfile" &>/dev/null
mkdir -p "$(dirname "$outfile")" &>/dev/null
echo "$content" > "$outfile"

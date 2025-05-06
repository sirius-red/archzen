#!/usr/bin/env bash

# This is a implementation test for the `__apply_hyde_blacklist_filter` function that
# will be used in a function that is in the ./archzen.sh file imported below.

# shellcheck disable=SC1091
# shellcheck source=./archzen.sh
source ./archzen.sh

# Temporary hyde_dir variable, The true is in the file ./archzen.sh imported above.
hyde_dir="./"
__LOG_FILE="/tmp/archzen_dev.log"

function __apply_hyde_blacklist_filter() {
	declare type="$1"
	shift
	declare -a blacklist=("$@")
	declare file

	case "$type" in
	package)
		file="$(realpath "${hyde_dir}/Scripts/pkg_core.lst")"
		;;
	service)
		file="$(realpath "${hyde_dir}/Scripts/system_ctl.lst")"
		;;
	*)
		__error "Invalid blacklist item type: $(__error_params "$type")"
		return 1
		;;
	esac

	for item in "${blacklist[@]}"; do
		declare -i line=0
		declare file_name

		line=$(__get_line "^${item}\s.*" "$file" 2>>"$__LOG_FILE" || __get_line "^${item}$" "$file" 2>>"$__LOG_FILE")
		file_name="$(basename "$file" 2>>"$__LOG_FILE")"

		__print "$(__info "Trying to remove the ${type} $(__info_params "$item") from $(__info_params "$file_name")")..."

		if [ ! -f "$file" ]; then
			__print -rn "$(__error "Trying to remove the ${type} $(__error_params "$item") from $(__error_params "$file_name")")... $(__error_params 'File not found!')"
		elif [ $line -gt 0 ]; then
			if sed -i "${line}d" "$file" &>>"$__LOG_FILE"; then
				__print -rn "$(__success "Trying to remove the ${type} $(__success_params "$item") from $(__success_params "$file_name")")... $(__success_params 'Success!')"
			else
				__print -rn "$(__error "Trying to remove the ${type} $(__error_params "$item") from $(__error_params "$file_name")")... $(__error_params 'Error in `sed` command!')"
			fi
		else
			__print -n " $(__info_params 'Skipped!')"
		fi
	done
}

echo "${__HYDE_PACKAGE_BLACKLIST[@]}"
__apply_hyde_blacklist_filter package "${__HYDE_PACKAGE_BLACKLIST[@]}"
__apply_hyde_blacklist_filter service "${__HYDE_SERVICE_BLACKLIST[@]}"

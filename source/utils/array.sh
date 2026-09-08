#!/usr/bin/env bash

function __join() {
	declare separator="$1"
	declare first_element="$2"
	shift 2
	declare -a rest_elements=("$@")
	declare joined="$first_element"

	if [[ "${#rest_elements[@]}" -gt 0 ]]; then
		for element in "${rest_elements[@]}"; do
			joined+="${separator}${element}"
		done
	fi

	printf '%s' "$joined"
}

#!/usr/bin/env bash

function __to_upper() {
	declare string="$1"

	printf "%s\n" "${string^^}"
}

function __to_lower() {
	declare string="$1"

	printf "%s\n" "${string,,}"
}

function __capitalize() {
	declare string="$1"
	declare first_char rest

	first_char="${string:0:1}"
	rest="${string:1}"

	printf "%s%s\n" "$(__to_upper "$first_char")" "$(__to_lower "$rest")"
}

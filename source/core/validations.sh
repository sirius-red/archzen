#!/usr/bin/env bash

__is_valid_semver() {
	declare version="$1"

	if [[ "$version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$ ]]; then
		return 0 # valid
	else
		return 1 # invalid
	fi
}

function __is_main_module() {
	[[ "${BASH_SOURCE[-1]}" == "${0}" ]]
}

function __is_integer() {
	declare value="$1"

	[[ "$value" =~ ^[0-9]+$ ]]
}

function __func_exists() {
	declare function_name=$1

	declare -F "$function_name" &>>"$__LOG_FILE"
}

function __starts_with() {
	declare string="$1"
	declare prefix="$2"

	[[ "$string" == "$prefix"* ]]
}

function __ends_with() {
	declare string="$1"
	declare suffix="$2"

	[[ "$string" == *"$suffix" ]]
}

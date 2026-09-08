#!/usr/bin/env bash

function __reset_line() {
	declare -i cols
	cols=$(tput cols)

	printf "\r%${cols}s\r" ""
}

function __print() {
	declare \
		text="" \
		flg_reset_line=false \
		flg_new_line=false

	while [ $# -gt 0 ]; do
		declare flag
		flag=$(echo "${1#-}" | xargs)

		if __starts_with "$1" '--'; then
			__error "$(__error_params "\`__print\`"): Invalid flag $(__error_params "\`${flag}\`")"
			return 1
		elif __starts_with "$1" '-'; then
			[[ "$1" == *r* ]] && flg_reset_line=true
			[[ "$1" == *n* ]] && flg_new_line=true
		else
			text="$1"
		fi

		shift
	done

	$flg_reset_line && {
		text="\r${text}"
		__reset_line
	}

	$flg_new_line && text+='\n'

	printf '%b' "$text"
}

function __get_color_code() {
	declare color="$1"

	case $color in
	black)
		printf "%d" 30
		;;
	bright-black)
		printf "%d" 90
		;;
	red)
		printf "%d" 31
		;;
	bright-red)
		printf "%d" 91
		;;
	green)
		printf "%d" 32
		;;
	bright-green)
		printf "%d" 92
		;;
	yellow)
		printf "%d" 33
		;;
	bright-yellow)
		printf "%d" 93
		;;
	blue)
		printf "%d" 34
		;;
	bright-blue)
		printf "%d" 94
		;;
	purple)
		printf "%d" 35
		;;
	bright-purple)
		printf "%d" 95
		;;
	cyan)
		printf "%d" 36
		;;
	bright-cyan)
		printf "%d" 96
		;;
	white)
		printf "%d" 37
		;;
	bright-white)
		printf "%d" 97
		;;
	*)
		printf "%d" 0
		;;
	esac
}

function __colorize() {
	declare -i color="$1"
	shift
	declare text="$*"
	declare is_normal_color=false
	declare is_bright_color=false

	__is_integer "$color" && {
		[[ "$color" -ge 30 && "$color" -le 37 ]] && is_normal_color=true
		[[ "$color" -ge 90 && "$color" -le 97 ]] && is_bright_color=true
	}

	if ! $is_normal_color && ! $is_bright_color; then
		declare -a valid_normal_color_codes=(
			"\033[1;30m30\033[0m"
			"\033[1;31m31\033[0m"
			"\033[1;32m32\033[0m"
			"\033[1;33m33\033[0m"
			"\033[1;34m34\033[0m"
			"\033[1;35m35\033[0m"
			"\033[1;36m36\033[0m"
			"\033[1;37m37\033[0m"
		)
		declare -a valid_bright_color_codes=(
			"\033[1;90m90\033[0m"
			"\033[1;91m91\033[0m"
			"\033[1;92m92\033[0m"
			"\033[1;93m93\033[0m"
			"\033[1;94m94\033[0m"
			"\033[1;95m95\033[0m"
			"\033[1;96m96\033[0m"
			"\033[1;97m97\033[0m"
		)

		echo -e "\033[1;31m[!!]\033[0m Invalid color code: \033[1;91m${color}\033[0m"
		(
			IFS=", "
			echo -e "     Valid color codes: ${valid_normal_color_codes[*]}"
			echo -e "                        ${valid_bright_color_codes[*]}"
		)
		exit 1
	fi

	printf "\033[1;%sm%s\033[0m" "$color" "$text"
}

function __bold() {
	declare text="$*"

	printf "\033[1m%s\033[0m" "$text"
}

function __underline() {
	declare text="$*"

	printf "\033[4m%s\033[0m" "$text"
}

function __italic() {
	declare text="$*"

	printf "\033[3m%s\033[0m" "$text"
}

function __bold_underline() {
	declare text="$*"

	printf "\033[1;4m%s\033[0m" "$text"
}

function __bold_italic() {
	declare text="$*"

	printf "\033[1;3m%s\033[0m" "$text"
}

function __bold_underline_italic() {
	declare text="$*"

	printf "\033[1;3;4m%s\033[0m" "$text"
}

function __underline_italic() {
	declare text="$*"

	printf "\033[3;4m%s\033[0m" "$text"
}

function __black() {
	declare text="$*"

	__colorize 30 "$text"
}

function __bright_black() {
	declare text="$*"

	__colorize 90 "$text"
}

function __red() {
	declare text="$*"

	__colorize 31 "$text"
}

function __bright_red() {
	declare text="$*"

	__colorize 91 "$text"
}

function __green() {
	declare text="$*"

	__colorize 32 "$text"
}

function __bright_green() {
	declare text="$*"

	__colorize 92 "$text"
}

function __yellow() {
	declare text="$*"

	__colorize 33 "$text"
}

function __bright_yellow() {
	declare text="$*"

	__colorize 93 "$text"
}

function __blue() {
	declare text="$*"

	__colorize 34 "$text"
}

function __bright_blue() {
	declare text="$*"

	__colorize 94 "$text"
}

function __purple() {
	declare text="$*"

	__colorize 35 "$text"
}

function __bright_purple() {
	declare text="$*"

	__colorize 95 "$text"
}

function __cyan() {
	declare text="$*"

	__colorize 36 "$text"
}

function __bright_cyan() {
	declare text="$*"

	__colorize 96 "$text"
}

function __white() {
	declare text="$*"

	__colorize 37 "$text"
}

function __bright_white() {
	declare text="$*"

	__colorize 97 "$text"
}

function __banner() {
	declare primary_color=$1
	declare secondary_color=$2
	declare pad=$3
	declare title=$4
	shift 4
	declare -a optional_params=("$@")
	declare author project_url license
	declare -a reference_urls=()

	# set correct color codes
	primary_color=$(__get_color_code "$primary_color")
	secondary_color=$(__get_color_code "$secondary_color")

	# parsing parameters
	for param in "${optional_params[@]}"; do
		# [[ "$param" =~ ^author: ]] && author="${param//author:/}"
		author="Sirius (https://github.com/sirius-red)"
		[[ "$param" =~ ^project_url: ]] && project_url="${param//project_url:/}"
		[[ "$param" =~ ^license: ]] && license="${param//license:/}"
		[[ "$param" =~ ^ref: ]] && reference_urls+=("${param//ref:/}")
	done

	# calculating banner width
	declare -i width=0
	declare -a info_lines=()
	[ -n "$author" ] && info_lines+=("Author    : $author")
	[ -n "$project_url" ] && info_lines+=("Project   : $project_url")
	[ -n "$license" ] && info_lines+=("License   : $license")
	if [ ${#reference_urls} -gt 0 ]; then
		info_lines+=("References: ${reference_urls[0]}")
		for url in "${reference_urls[@]:1}"; do
			info_lines+=("REF_URL:    $url")
		done
	fi

	# determine the maximum width
	for line in "${info_lines[@]}"; do
		((${#line} > width)) && width=${#line}
	done
	((${#title} > width)) && width=${#title}
	width=$((width + 8))

	# calculating padding to center the title
	declare -i title_padding=$(((width - ${#title} - 4) / 2))

	# formatting function
	declare edge
	edge=$(printf "%${width}s" | tr ' ' "$pad")
	pad="${pad}${pad}"

	# coloring
	declare separator
	edge="$(__colorize "$secondary_color" "$edge")"
	pad="$(__colorize "$secondary_color" "$pad")"
	title="$(__colorize "$primary_color" "$title")"
	separator="$(__colorize "$secondary_color" "$(printf "%$((width - 4))s" | tr ' ' '-')")"

	# formatting and displaying the banner according to the parameters passed
	echo "$edge"
	printf "${pad}%$((width - 4))s${pad}\n"
	printf "${pad}%$((title_padding + ${#title}))s%$((width - title_padding - ${#title} + 7))s${pad}\n" "$title"
	printf "${pad}%$((width - 4))s${pad}\n"
	[ "${#info_lines}" -gt 0 ] && printf "${pad}%s${pad}\n" "$separator"
	for line in "${info_lines[@]}"; do
		k="$(echo "$line" | cut -d':' -f1):"
		value="$(echo "$line" | cut -d':' -f2-)"
		if [[ "$line" =~ ^REF_URL: ]]; then
			k="${k//?/ }"
		else
			printf "${pad}%$((width - 4))s${pad}\n"
		fi
		echo -e "${pad} $k $(__colorize "$primary_color" "$value") $(printf "%$((width - ${#k} - ${#value} - 7))s")${pad}"
	done
	[ "${#info_lines}" -gt 0 ] && printf "${pad}%$((width - 4))s${pad}\n"
	echo "$edge"
	echo
}

function __log() {
	declare plain="$1"
	declare formatted="$2"

	[ -z "$formatted" ] && formatted="$plain"

	$__QUIET || printf "%s\n" "$formatted"
	[ -f "$__LOG_FILE" ] && printf "%s\n" "$plain" >>"$__LOG_FILE"
}

function __title() {
	declare message formatted
	message="[#] $*"
	formatted="$(__purple "[#]") $*"

	__log "$message" "$formatted"
	return 0
}

function __title_params() {
	declare params="$*"

	__bright_purple "$params"
}

function __question() {
	declare message="$1"
	declare formatted="$2"
	declare quiet=$__QUIET
	message="[?] ${message}"
	formatted="$(__cyan "[?]") ${message}"

	__QUIET=true
	__log "$message" "$formatted"
	__QUIET=$quiet
	return 0
}

function __question_params() {
	declare params="$*"

	__bright_cyan "$params"
}

function __info() {
	declare message formatted
	message="[i] $*"
	formatted="$(__blue "[i]") $*"

	__log "$message" "$formatted"
	return 0
}

function __info_params() {
	declare params="$*"

	__bright_blue "$params"
}

function __success() {
	declare message formatted
	message="[+] $*"
	formatted="$(__green "[+]") $*"

	__log "$message" "$formatted"
	return 0
}

function __success_params() {
	declare params="$*"

	__bright_green "$params"
}

function __warn() {
	declare message formatted
	message="[!] $*"
	formatted="$(__yellow "[!]") $*"

	__log "$message" "$formatted"
	return 0
}

function __warn_params() {
	declare params="$*"

	__bright_yellow "$params"
}

function __error() {
	declare message formatted
	message="[x] $*"
	formatted="$(__red "[x]") $*"

	__log "$message" "$formatted"
	return 1
}

function __error_params() {
	declare params="$*"

	__bright_red "$params"
}

function __confirm() {
	declare question="$*"
	declare plain_question="$* [Y/n]"
	declare -i return_code=2
	declare quiet=$__QUIET
	question="${question} [$(__bright_green Y)/$(__bright_red n)]"

	while [ $return_code -eq 2 ]; do
		printf "\r%s %s: " "$(__cyan "[?]")" "$question"
		read -r -N 1 answer

		case $answer in
		[Yy]*)
			return_code=0
			;;
		[Nn]*)
			return_code=1
			;;
		esac
	done
	printf "\n"

	__QUIET=true
	plain_question="${plain_question}: ${answer}"
	question="${question}: $(__question_params "$answer")"
	__question "$plain_question" "$question"
	__QUIET=$quiet

	return $return_code
}

function __show_log_msglist() {
	declare log_func="__${1}"
	shift 1
	declare msglist=("$@")

	[[ -z "${msglist[*]}" || ${#msglist[@]} -le 0 ]] && return 0

	__log ""
	for msg in "${msglist[@]}"; do
		$log_func "$msg"
	done
}

function __tab() {
	declare -i count="$1"

	for ((i = 0; i < count; i++)); do
		printf '\t'
	done
}

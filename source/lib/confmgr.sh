#!/usr/bin/env bash

# ==============================================================================
# confmgr — Self-contained configuration file editor
# ==============================================================================
# A high-performance, safe, and extensible configuration file editor.
# Supports .ini and .conf formats out of the box.
#
# DEPENDENCIES: bash (4.0+), sed, grep, mktemp, mv, chmod, stat, cat — all
#               standard on any Linux system.
#
# ADDING NEW FORMATS:
#   1. Create __confmgr_parse_<format>()  — sets __cm_sep and __cm_comment_char
#   2. Create __confmgr_rebuild_<format>() — (optional) post-process the output
#   3. Add the extension(s) to __confmgr_detect_format()
#
# USAGE:
#   confmgr <operation> <file> [options...]
#
# OPERATIONS:
#   set     <file> <keypath> <value>        — Set a key=value (creates if missing)
#   get     <file> <keypath>                — Print the value of a key
#   delete  <file> <keypath>                — Remove a key entirely
#   comment <file> <keypath>                — Comment out a key
#   uncomment <file> <keypath>              — Uncomment a key
#   exists  <file> <keypath>                — Return 0 if key exists, 1 otherwise
#   section-add    <file> <section>         — Add a new section header
#   section-delete <file> <section>         — Remove an entire section and its keys
#
#   <keypath> format: [section.][subsection.]key
#   Supports parsing types like boolean and number, and unquoting strings in `get`.
#
# OPTIONS:
#   --format <ini|conf>   — Force a format instead of auto-detecting from extension
#   --separator <char>    — Override the key-value separator (default: '=' for ini/conf)
#   --backup              — Create a .bak backup before modifying
#   --create              — Create the file if it doesn't exist
#
# EXAMPLES:
#   confmgr set /etc/pacman.conf misc.Color true
#   confmgr get /etc/pacman.conf options.ParallelDownloads
#   confmgr delete ~/.config/app.ini ui.theme
#   confmgr set myfile.conf key value --format conf --backup
# ==============================================================================
# shellcheck disable=SC2329
function confmgr() {
	# -- Internal format handlers ----------------------------------------------

	# Sets format-specific variables: __cm_sep, __cm_comment_char, __cm_space_around_sep
	function __confmgr_parse_ini() {
		__cm_sep='='
		__cm_comment_char=';'
		__cm_space_around_sep=true
	}

	function __confmgr_parse_conf() {
		__cm_sep='='
		__cm_comment_char='#'
		__cm_space_around_sep=true
	}

	# Detect format from file extension, returns format name string
	function __confmgr_detect_format() {
		declare file_path="$1"
		declare ext="${file_path##*.}"

		case "$ext" in
			ini)  printf 'ini'  ;;
			conf) printf 'conf' ;;
			*)    printf ''     ;;
		esac
	}

	# -- Internal helpers ------------------------------------------------------

	function __confmgr_err() {
		printf 'confmgr: %s\n' "$1" >&2
		return 1
	}

	# Build the regex to match a key line (optionally commented)
	# Output: ERE pattern string
	function __confmgr_key_pattern() {
		declare key="$1"
		declare comment_char="$2"
		declare escaped_key escaped_sep

		# Escape regex special chars in key and separator
		escaped_key=$(printf '%s' "$key" | sed 's/[.[\*^$()+?{|\\]/\\&/g')
		escaped_sep=$(printf '%s' "$__cm_sep" | sed 's/[.[\*^$()+?{|\\]/\\&/g')

		# Match: optional comment + optional whitespace + key + optional whitespace + separator
		if [[ -n "$escaped_sep" ]]; then
			printf '^[%s]*[[:space:]]*%s[[:space:]]*%s' "$comment_char" "$escaped_key" "$escaped_sep"
		else
			printf '^[%s]*[[:space:]]*%s([[:space:]]|$)' "$comment_char" "$escaped_key"
		fi
	}

	# Build the regex to match a section header
	function __confmgr_section_pattern() {
		declare section="$1"
		declare escaped_section

		escaped_section=$(printf '%s' "$section" | sed 's/[.[\*^$()+?{|\\]/\\&/g')
		printf '^\[%s\]' "$escaped_section"
	}

	# Find the line range of a section: returns "start_line end_line" (1-indexed)
	# end_line is the last line of the section (before next section or EOF)
	function __confmgr_section_range() {
		declare file_path="$1"
		declare section="$2"
		declare section_pat
		declare -i start_line=0 end_line=0 total_lines

		section_pat=$(__confmgr_section_pattern "$section")
		total_lines=$(wc -l < "$file_path")

		# Find the section header line
		start_line=$(grep -n -m1 -E "$section_pat" "$file_path" 2>/dev/null | cut -d: -f1)

		if [[ -z "$start_line" || "$start_line" -eq 0 ]]; then
			printf '0 0'
			return 1
		fi

		# Find the next section header after this one
		if [[ $start_line -lt $total_lines ]]; then
			end_line=$(tail -n +"$((start_line + 1))" "$file_path" | grep -n -m1 -E '^\[' 2>/dev/null | cut -d: -f1)
			if [[ -n "$end_line" && "$end_line" -gt 0 ]]; then
				end_line=$((start_line + end_line - 1))
			else
				end_line=$total_lines
			fi
		else
			end_line=$total_lines
		fi

		printf '%d %d' "$start_line" "$end_line"
	}

	# Perform an atomic write: edits are applied to a temp file, then mv'd over
	# $1 = original file, stdin = new content
	function __confmgr_atomic_write() {
		declare target="$1"
		declare tmp_file dir_path
		declare -i original_mode=0

		dir_path=$(dirname "$target")
		tmp_file=$(mktemp "${dir_path}/.confmgr.XXXXXX") || return 1

		# Preserve original permissions
		if [[ -f "$target" ]]; then
			original_mode=$(stat -c '%a' "$target" 2>/dev/null) || original_mode=644
		else
			original_mode=644
		fi

		# Write stdin to temp file
		cat > "$tmp_file" || { rm -f "$tmp_file"; return 1; }

		# Set permissions before moving
		chmod "$original_mode" "$tmp_file" 2>/dev/null

		# Atomic replace
		mv -f "$tmp_file" "$target" || { rm -f "$tmp_file"; return 1; }
	}

	# Format a key=value line according to current format settings
	function __confmgr_format_kv() {
		declare key="$1"
		declare value="$2"

		if [[ -z "$__cm_sep" ]]; then
			if [[ -n "$value" ]]; then
				printf '%s %s' "$key" "$value"
			else
				printf '%s' "$key"
			fi
		elif $__cm_space_around_sep; then
			printf '%s %s %s' "$key" "$__cm_sep" "$value"
		else
			printf '%s%s%s' "$key" "$__cm_sep" "$value"
		fi
	}

	# -- Core operations -------------------------------------------------------

	function __confmgr_op_set() {
		declare file_path="$1"
		declare key="$2"
		declare value="$3"
		declare section="$4"
		declare key_pat new_line
		declare -i found=0

		key_pat=$(__confmgr_key_pattern "$key" "$__cm_comment_char")
		new_line=$(__confmgr_format_kv "$key" "$value")

		if [[ -n "$section" ]]; then
			declare range start_line end_line
			if ! range=$(__confmgr_section_range "$file_path" "$section"); then
				__confmgr_op_section_add "$file_path" "$section" || return 1
				range=$(__confmgr_section_range "$file_path" "$section") || return 1
			fi
			read -r start_line end_line <<< "$range"

			# Check if key exists within section range
			if sed -n "${start_line},${end_line}p" "$file_path" | grep -qE "$key_pat"; then
				found=1
			fi

			if [[ $found -eq 1 ]]; then
				# Replace the first matching key in the section
				sed "${start_line},${end_line}s|${key_pat}.*|${new_line}|" "$file_path" \
					| __confmgr_atomic_write "$file_path"
			else
				# Insert new key after section header
				sed "${start_line}a\\${new_line}" "$file_path" \
					| __confmgr_atomic_write "$file_path"
			fi
		else
			if grep -qE "$key_pat" "$file_path" 2>/dev/null; then
				found=1
			fi

			if [[ $found -eq 1 ]]; then
				sed "s|${key_pat}.*|${new_line}|" "$file_path" \
					| __confmgr_atomic_write "$file_path"
			else
				# Append to end of file
				{ cat "$file_path"; printf '%s\n' "$new_line"; } \
					| __confmgr_atomic_write "$file_path"
			fi
		fi
	}

	function __confmgr_op_get() {
		declare file_path="$1"
		declare key="$2"
		declare section="$3"
		declare opt_export="$4"
		declare full_keypath="$5"
		declare key_pat result escaped_key escaped_sep

		escaped_key=$(printf '%s' "$key" | sed 's/[.[\*^$()+?{|\\]/\\&/g')
		escaped_sep=$(printf '%s' "$__cm_sep" | sed 's/[.[\*^$()+?{|\\]/\\&/g')

		if [[ -n "$section" ]]; then
			declare range start_line end_line
			range=$(__confmgr_section_range "$file_path" "$section") || {
				__confmgr_err "section '[$section]' not found in '$file_path'"
				return 1
			}
			read -r start_line end_line <<< "$range"

			if [[ -n "$escaped_sep" ]]; then
				result=$(sed -n "${start_line},${end_line}p" "$file_path" \
					| grep -E "^[[:space:]]*${escaped_key}[[:space:]]*${escaped_sep}" \
					| head -1 \
					| sed "s/^[[:space:]]*[^${__cm_sep}]*${__cm_sep}[[:space:]]*//" \
					| sed 's/[[:space:]]*$//')
			else
				result=$(sed -n "${start_line},${end_line}p" "$file_path" \
					| grep -E "^[[:space:]]*${escaped_key}([[:space:]]|$)" \
					| head -1 \
					| sed "s/^[[:space:]]*${escaped_key}[[:space:]]*//" \
					| sed 's/[[:space:]]*$//')
			fi
		else
			if [[ -n "$escaped_sep" ]]; then
				result=$(grep -E "^[[:space:]]*${escaped_key}[[:space:]]*${escaped_sep}" "$file_path" \
					| head -1 \
					| sed "s/^[[:space:]]*[^${__cm_sep}]*${__cm_sep}[[:space:]]*//" \
					| sed 's/[[:space:]]*$//')
			else
				result=$(grep -E "^[[:space:]]*${escaped_key}([[:space:]]|$)" "$file_path" \
					| head -1 \
					| sed "s/^[[:space:]]*${escaped_key}[[:space:]]*//" \
					| sed 's/[[:space:]]*$//')
			fi
		fi

		if [[ -z "$result" ]]; then
			return 1
		fi

		if [[ "$result" =~ ^\"(.*)\"$ ]] || [[ "$result" =~ ^\'(.*)\'$ ]]; then
			result="${BASH_REMATCH[1]}"
		fi

		if [[ "$opt_export" == true ]]; then
			declare target_var
			target_var="$(echo "$full_keypath" | sed 's/\./_/g; s/\([a-z0-9]\)\([A-Z]\)/\1_\2/g' | tr '[:lower:]' '[:upper:]')"
			declare -gx "$target_var=$result"
		else
			printf '%s\n' "$result"
		fi

		declare lower_res="${result,,}"
		if [[ "$lower_res" == "false" || "$lower_res" == "no" || "$lower_res" == "0" ]]; then
			return 1
		fi

		return 0
	}

	function __confmgr_op_delete() {
		declare file_path="$1"
		declare key="$2"
		declare section="$3"
		declare key_pat

		key_pat=$(__confmgr_key_pattern "$key" "$__cm_comment_char")

		if [[ -n "$section" ]]; then
			declare range start_line end_line
			range=$(__confmgr_section_range "$file_path" "$section") || {
				__confmgr_err "section '[$section]' not found in '$file_path'"
				return 1
			}
			read -r start_line end_line <<< "$range"

			sed -n "${start_line},${end_line}p" "$file_path" | grep -qE "$key_pat" || {
				__confmgr_err "key '$key' not found in section '[$section]'"
				return 1
			}

			sed "${start_line},${end_line}{/${key_pat}/d}" "$file_path" \
				| __confmgr_atomic_write "$file_path"
		else
			grep -qE "$key_pat" "$file_path" 2>/dev/null || {
				__confmgr_err "key '$key' not found in '$file_path'"
				return 1
			}

			sed "/${key_pat}/d" "$file_path" \
				| __confmgr_atomic_write "$file_path"
		fi
	}

	function __confmgr_op_comment() {
		declare file_path="$1"
		declare key="$2"
		declare section="$3"
		declare escaped_key escaped_sep active_pat

		escaped_key=$(printf '%s' "$key" | sed 's/[.[\*^$()+?{|\\]/\\&/g')
		escaped_sep=$(printf '%s' "$__cm_sep" | sed 's/[.[\*^$()+?{|\\]/\\&/g')
		# Match only active (non-commented) lines
		if [[ -n "$escaped_sep" ]]; then
			active_pat="^[[:space:]]*${escaped_key}[[:space:]]*${escaped_sep}"
		else
			active_pat="^[[:space:]]*${escaped_key}([[:space:]]|$)"
		fi

		if [[ -n "$section" ]]; then
			declare range start_line end_line
			range=$(__confmgr_section_range "$file_path" "$section") || {
				__confmgr_err "section '[$section]' not found in '$file_path'"
				return 1
			}
			read -r start_line end_line <<< "$range"

			sed -n "${start_line},${end_line}p" "$file_path" | grep -qE "$active_pat" || {
				__confmgr_err "active key '$key' not found in section '[$section]'"
				return 1
			}

			if [[ -n "$escaped_sep" ]]; then
				sed "${start_line},${end_line}s|^\\([[:space:]]*\\)\\(${escaped_key}[[:space:]]*${escaped_sep}\\)|\\1${__cm_comment_char} \\2|" "$file_path" \
					| __confmgr_atomic_write "$file_path"
			else
				sed "${start_line},${end_line}s|^\\([[:space:]]*\\)\\(${escaped_key}\\)|\\1${__cm_comment_char} \\2|" "$file_path" \
					| __confmgr_atomic_write "$file_path"
			fi
		else
			grep -qE "$active_pat" "$file_path" 2>/dev/null || {
				__confmgr_err "active key '$key' not found in '$file_path'"
				return 1
			}

			if [[ -n "$escaped_sep" ]]; then
				sed "s|^\\([[:space:]]*\\)\\(${escaped_key}[[:space:]]*${escaped_sep}\\)|\\1${__cm_comment_char} \\2|" "$file_path" \
					| __confmgr_atomic_write "$file_path"
			else
				sed "s|^\\([[:space:]]*\\)\\(${escaped_key}\\)|\\1${__cm_comment_char} \\2|" "$file_path" \
					| __confmgr_atomic_write "$file_path"
			fi
		fi
	}

	function __confmgr_op_uncomment() {
		declare file_path="$1"
		declare key="$2"
		declare section="$3"
		declare escaped_key escaped_sep commented_pat

		escaped_key=$(printf '%s' "$key" | sed 's/[.[\*^$()+?{|\\]/\\&/g')
		escaped_sep=$(printf '%s' "$__cm_sep" | sed 's/[.[\*^$()+?{|\\]/\\&/g')
		# Match commented lines: comment_char + optional space + key
		if [[ -n "$escaped_sep" ]]; then
			commented_pat="^[[:space:]]*[${__cm_comment_char}]+[[:space:]]*${escaped_key}[[:space:]]*${escaped_sep}"
		else
			commented_pat="^[[:space:]]*[${__cm_comment_char}]+[[:space:]]*${escaped_key}([[:space:]]|$)"
		fi

		if [[ -n "$section" ]]; then
			declare range start_line end_line
			range=$(__confmgr_section_range "$file_path" "$section") || {
				__confmgr_err "section '[$section]' not found in '$file_path'"
				return 1
			}
			read -r start_line end_line <<< "$range"

			sed -n "${start_line},${end_line}p" "$file_path" | grep -qE "$commented_pat" || {
				__confmgr_err "commented key '$key' not found in section '[$section]'"
				return 1
			}

			if [[ -n "$escaped_sep" ]]; then
				sed "${start_line},${end_line}s|^\\([[:space:]]*\\)[${__cm_comment_char}][[:space:]]*\\(${escaped_key}[[:space:]]*${escaped_sep}\\)|\\1\\2|" "$file_path" \
					| __confmgr_atomic_write "$file_path"
			else
				sed "${start_line},${end_line}s|^\\([[:space:]]*\\)[${__cm_comment_char}][[:space:]]*\\(${escaped_key}\\)|\\1\\2|" "$file_path" \
					| __confmgr_atomic_write "$file_path"
			fi
		else
			grep -qE "$commented_pat" "$file_path" 2>/dev/null || {
				__confmgr_err "commented key '$key' not found in '$file_path'"
				return 1
			}

			if [[ -n "$escaped_sep" ]]; then
				sed "s|^\\([[:space:]]*\\)[${__cm_comment_char}][[:space:]]*\\(${escaped_key}[[:space:]]*${escaped_sep}\\)|\\1\\2|" "$file_path" \
					| __confmgr_atomic_write "$file_path"
			else
				sed "s|^\\([[:space:]]*\\)[${__cm_comment_char}][[:space:]]*\\(${escaped_key}\\)|\\1\\2|" "$file_path" \
					| __confmgr_atomic_write "$file_path"
			fi
		fi
	}

	function __confmgr_op_exists() {
		declare file_path="$1"
		declare key="$2"
		declare section="$3"
		declare escaped_key escaped_sep active_pat

		escaped_key=$(printf '%s' "$key" | sed 's/[.[\*^$()+?{|\\]/\\&/g')
		escaped_sep=$(printf '%s' "$__cm_sep" | sed 's/[.[\*^$()+?{|\\]/\\&/g')
		if [[ -n "$escaped_sep" ]]; then
			active_pat="^[[:space:]]*${escaped_key}[[:space:]]*${escaped_sep}"
		else
			active_pat="^[[:space:]]*${escaped_key}([[:space:]]|$)"
		fi

		if [[ -n "$section" ]]; then
			declare range start_line end_line
			range=$(__confmgr_section_range "$file_path" "$section") || return 1
			read -r start_line end_line <<< "$range"

			sed -n "${start_line},${end_line}p" "$file_path" | grep -qE "$active_pat"
		else
			grep -qE "$active_pat" "$file_path" 2>/dev/null
		fi
	}

	function __confmgr_op_section_add() {
		declare file_path="$1"
		declare section="$2"
		declare section_pat

		section_pat=$(__confmgr_section_pattern "$section")

		if grep -qE "$section_pat" "$file_path" 2>/dev/null; then
			__confmgr_err "section '[$section]' already exists in '$file_path'"
			return 1
		fi

		{ cat "$file_path"; printf '\n[%s]\n' "$section"; } \
			| __confmgr_atomic_write "$file_path"
	}

	function __confmgr_op_section_delete() {
		declare file_path="$1"
		declare section="$2"
		declare range start_line end_line

		range=$(__confmgr_section_range "$file_path" "$section") || {
			__confmgr_err "section '[$section]' not found in '$file_path'"
			return 1
		}
		read -r start_line end_line <<< "$range"

		sed "${start_line},${end_line}d" "$file_path" \
			| __confmgr_atomic_write "$file_path"
	}

	# -- Argument parsing & dispatch -------------------------------------------

	declare operation="$1"
	shift || true

	if [[ -z "$operation" ]]; then
		__confmgr_err "missing operation. Usage: confmgr <operation> <file> [options...]"
		return 1
	fi

	# Collect positional args and flags
	declare -a positional_args=()
	declare file_path=""
	declare opt_format="" opt_separator="" opt_backup=false opt_create=false opt_export=false
	declare opt_separator_set=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--format)
				opt_format="$2"
				shift 2
				;;
			--separator)
				opt_separator="$2"
				opt_separator_set=true
				shift 2
				;;
			--backup)
				opt_backup=true
				shift
				;;
			--create)
				opt_create=true
				shift
				;;
			--export|-e)
				opt_export=true
				shift
				;;
			--)
				shift
				positional_args+=("$@")
				break
				;;
			--*)
				__confmgr_err "unknown option: $1"
				return 1
				;;
			*)
				if [[ -z "$file_path" ]]; then
					file_path="$1"
				else
					positional_args+=("$1")
				fi
				shift
				;;
		esac
	done

	# Handle file existence
	if [[ -z "$file_path" ]]; then
		__confmgr_err "missing file path. Usage: confmgr <operation> <file> [options...]"
		return 1
	fi

	if [[ ! -f "$file_path" ]]; then
		if $opt_create; then
			declare parent_dir
			parent_dir=$(dirname "$file_path")
			[[ -d "$parent_dir" ]] || mkdir -p "$parent_dir" || {
				__confmgr_err "failed to create directory '$parent_dir'"
				return 1
			}
			touch "$file_path" || {
				__confmgr_err "failed to create file '$file_path'"
				return 1
			}
		elif [[ "$operation" == "get" || "$operation" == "exists" ]]; then
			# For read-only operations, just return failure
			return 1
		else
			__confmgr_err "file '$file_path' does not exist (use --create to create it)"
			return 1
		fi
	fi

	# Detect or apply format
	declare format="$opt_format"
	if [[ -z "$format" ]]; then
		format=$(__confmgr_detect_format "$file_path")
		if [[ -z "$format" ]]; then
			__confmgr_err "cannot detect format for '$file_path'. Use --format <ini|conf>"
			return 1
		fi
	fi

	# Initialize format-specific variables
	declare __cm_sep __cm_comment_char __cm_space_around_sep=false

	if declare -F "__confmgr_parse_${format}" &>/dev/null; then
		"__confmgr_parse_${format}"
	else
		__confmgr_err "unsupported format: '$format'"
		return 1
	fi

	# Override separator if specified
	if $opt_separator_set; then
		__cm_sep="$opt_separator"
	fi

	# Create backup if requested
	if { $CONFMGR_ENABLE_BACKUP || $opt_backup; } && [[ -f "$file_path" ]]; then
		cp -p "$file_path" "${file_path}.bak" || {
			__confmgr_err "failed to create backup of '$file_path'"
			return 1
		}
	fi

	# Dispatch operation
	case "$operation" in
		set)
			declare ce_keypath="${positional_args[0]}"
			declare ce_value="${positional_args[1]}"
			declare ce_section="" ce_key="$ce_keypath"

			if [[ -z "$ce_keypath" ]]; then
				__confmgr_err "'set' requires: confmgr set <file> <keypath> <value>"
				return 1
			fi

			if [[ "$ce_keypath" == *.* ]]; then
				ce_section="${ce_keypath%.*}"
				ce_key="${ce_keypath##*.}"
			fi

			__confmgr_op_set "$file_path" "$ce_key" "$ce_value" "$ce_section"
			;;
		get)
			declare ce_keypath="${positional_args[0]}"
			declare ce_section="" ce_key="$ce_keypath"

			if [[ -z "$ce_keypath" ]]; then
				__confmgr_err "'get' requires: confmgr get <file> <keypath>"
				return 1
			fi

			if [[ "$ce_keypath" == *.* ]]; then
				ce_section="${ce_keypath%.*}"
				ce_key="${ce_keypath##*.}"
			fi

			__confmgr_op_get "$file_path" "$ce_key" "$ce_section" "$opt_export" "$ce_keypath"
			;;
		delete)
			declare ce_keypath="${positional_args[0]}"
			declare ce_section="" ce_key="$ce_keypath"

			if [[ -z "$ce_keypath" ]]; then
				__confmgr_err "'delete' requires: confmgr delete <file> <keypath>"
				return 1
			fi

			if [[ "$ce_keypath" == *.* ]]; then
				ce_section="${ce_keypath%.*}"
				ce_key="${ce_keypath##*.}"
			fi

			__confmgr_op_delete "$file_path" "$ce_key" "$ce_section"
			;;
		comment)
			declare ce_keypath="${positional_args[0]}"
			declare ce_section="" ce_key="$ce_keypath"

			if [[ -z "$ce_keypath" ]]; then
				__confmgr_err "'comment' requires: confmgr comment <file> <keypath>"
				return 1
			fi

			if [[ "$ce_keypath" == *.* ]]; then
				ce_section="${ce_keypath%.*}"
				ce_key="${ce_keypath##*.}"
			fi

			__confmgr_op_comment "$file_path" "$ce_key" "$ce_section"
			;;
		uncomment)
			declare ce_keypath="${positional_args[0]}"
			declare ce_section="" ce_key="$ce_keypath"

			if [[ -z "$ce_keypath" ]]; then
				__confmgr_err "'uncomment' requires: confmgr uncomment <file> <keypath>"
				return 1
			fi

			if [[ "$ce_keypath" == *.* ]]; then
				ce_section="${ce_keypath%.*}"
				ce_key="${ce_keypath##*.}"
			fi

			__confmgr_op_uncomment "$file_path" "$ce_key" "$ce_section"
			;;
		exists)
			declare ce_keypath="${positional_args[0]}"
			declare ce_section="" ce_key="$ce_keypath"

			if [[ -z "$ce_keypath" ]]; then
				__confmgr_err "'exists' requires: confmgr exists <file> <keypath>"
				return 1
			fi

			if [[ "$ce_keypath" == *.* ]]; then
				ce_section="${ce_keypath%.*}"
				ce_key="${ce_keypath##*.}"
			fi

			__confmgr_op_exists "$file_path" "$ce_key" "$ce_section"
			;;
		section-add)
			declare ce_section="${positional_args[0]}"

			if [[ -z "$ce_section" ]]; then
				__confmgr_err "'section-add' requires: confmgr section-add <file> <section>"
				return 1
			fi

			__confmgr_op_section_add "$file_path" "$ce_section"
			;;
		section-delete)
			declare ce_section="${positional_args[0]}"

			if [[ -z "$ce_section" ]]; then
				__confmgr_err "'section-delete' requires: confmgr section-delete <file> <section>"
				return 1
			fi

			__confmgr_op_section_delete "$file_path" "$ce_section"
			;;
		*)
			__confmgr_err "unknown operation: '$operation'. Valid: set, get, delete, comment, uncomment, exists, section-add, section-delete"
			return 1
			;;
	esac
}

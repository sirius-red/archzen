#!/usr/bin/env bash

# ==============================================================================
# cli_parser — Self-contained declarative CLI engine for YAML and JSON
# ==============================================================================
# Parses CLI arguments based on a declarative configuration file (.yml, .yaml, .json).
# Supports commands, subcommands, aliases, typed positional arguments, enum validation,
# global flags (--dev, --force, --help, --version), automated colorful help output,
# and direct action dispatching.
#
# USAGE:
#   cli_parser <config_file> "$@"
# ==============================================================================
# shellcheck disable=SC2329
function cli_parser() {
	declare __cli_config_file="$1"
	shift 1

	if [[ -z "$__cli_config_file" || ! -f "$__cli_config_file" ]]; then
		printf 'cli_parser: configuration file not found: %s\n' "$__cli_config_file" >&2
		return 1
	fi

	# -- Format detection and JSON AST loading ---------------------------------
	declare __cli_format=""
	case "$__cli_config_file" in
		*.json) __cli_format="json" ;;
		*.yaml|*.yml) __cli_format="yaml" ;;
		*)
			if grep -q '^[[:space:]]*{' "$__cli_config_file" 2>/dev/null; then
				__cli_format="json"
			else
				__cli_format="yaml"
			fi
			;;
	esac

	# Parse config into JSON in memory for unified querying with jq
	declare __cli_json=""
	if [[ "$__cli_format" == "json" ]]; then
		if ! command -v jq &>>"$__LOG_FILE"; then
			printf 'cli_parser: jq is required to parse JSON config files\n' >&2
			return 1
		fi
		__cli_json="$(cat "$__cli_config_file")"
	else
		if ! command -v yq &>>"$__LOG_FILE"; then
			printf 'cli_parser: yq is required to parse YAML config files\n' >&2
			return 1
		fi
		__cli_json="$(yq -o=json '.' "$__cli_config_file" 2>>"$__LOG_FILE")"
		if [[ -z "$__cli_json" ]]; then
			printf 'cli_parser: failed to parse YAML configuration with yq\n' >&2
			return 1
		fi
	fi

	# -- Internal query helper -------------------------------------------------
	function __cli_get() {
		declare filter="$1"
		jq -r "$filter // empty" <<<"$__cli_json" 2>/dev/null
	}

	function __cli_get_json() {
		declare filter="$1"
		jq -c "$filter // empty" <<<"$__cli_json" 2>/dev/null
	}

	# -- Metadata extraction ---------------------------------------------------
	declare __cli_name __cli_ver __cli_desc __cli_author __cli_lic __cli_usage_custom
	__cli_name="$(__cli_get '.name')"
	__cli_name="${__cli_name:-archzen}"
	__cli_ver="$(__cli_get '.version')"
	__cli_ver="${__cli_ver:-$__VERSION}"
	__cli_desc="$(__cli_get '.description')"
	__cli_author="$(__cli_get '.author')"
	__cli_lic="$(__cli_get '.license')"
	__cli_usage_custom="$(__cli_get '.usage')"

	# -- Version Display -------------------------------------------------------
	function __cli_show_version() {
		echo "${__cli_name^} $(__bright_green "v${__cli_ver}")"
	}

	# -- Dynamic Usage Generator -----------------------------------------------
	function __cli_generate_usage() {
		declare cmd="$1"
		declare subcmd="$2"
		declare usage_out=""

		if [[ -n "$cmd" && -n "$subcmd" ]]; then
			usage_out="$(__purple "$__cli_name") $(__bright_blue "$cmd") $(__bright_blue "$subcmd")"
			declare args_json
			args_json="$(__cli_get_json ".commands[\"$cmd\"][\"$subcmd\"].args")"
			if [[ "$args_json" != "empty" && "$args_json" != "null" && -n "$args_json" ]]; then
				while IFS= read -r arg_item; do
					[[ -z "$arg_item" ]] && continue
					declare a_name a_req a_var
					a_name="$(jq -r '.name' <<<"$arg_item")"
					a_req="$(jq -r '.required // true' <<<"$arg_item")"
					a_var="$(jq -r '.variadic // false' <<<"$arg_item")"

					if [[ "$a_req" == "true" ]]; then
						if [[ "$a_var" == "true" ]]; then
							usage_out+=" $(__yellow "<${a_name}>...")"
						else
							usage_out+=" $(__yellow "<${a_name}>")"
						fi
					else
						if [[ "$a_var" == "true" ]]; then
							usage_out+=" $(__yellow "[${a_name}...]")"
						else
							usage_out+=" $(__yellow "[${a_name}]")"
						fi
					fi
				done < <(jq -c '.[]' <<<"$args_json" 2>/dev/null)
			fi
		elif [[ -n "$cmd" ]]; then
			declare is_group
			is_group="$(__cli_get ".commands[\"$cmd\"] | type")"
			declare has_action
			has_action="$(__cli_get ".commands[\"$cmd\"].action")"
			if [[ "$is_group" == "object" && -z "$has_action" ]]; then
				usage_out="$(__purple "$__cli_name") $(__bright_blue "$cmd") $(__bright_blue "<subcommand>") $(__yellow "[<args>...]")"
			else
				usage_out="$(__purple "$__cli_name") $(__bright_blue "$cmd")"
				declare args_json
				args_json="$(__cli_get_json ".commands[\"$cmd\"].args")"
				if [[ "$args_json" != "empty" && "$args_json" != "null" && -n "$args_json" ]]; then
					while IFS= read -r arg_item; do
						[[ -z "$arg_item" ]] && continue
						declare a_name a_req a_var
						a_name="$(jq -r '.name' <<<"$arg_item")"
						a_req="$(jq -r '.required // true' <<<"$arg_item")"
						a_var="$(jq -r '.variadic // false' <<<"$arg_item")"

						if [[ "$a_req" == "true" ]]; then
							usage_out+=" $(__yellow "<${a_name}>")"
						else
							usage_out+=" $(__yellow "[${a_name}]")"
						fi
					done < <(jq -c '.[]' <<<"$args_json" 2>/dev/null)
				fi
			fi
		else
			usage_out="$(__purple "$__cli_name") $(__yellow "[flags]") $(__bright_blue "<command>") $(__yellow "[<args>...]")"
		fi

		echo -e "$usage_out"
	}

	# -- Help Formatting (Compact Style with ArchZen theme) -------------------
	function __cli_show_help() {
		declare target_cmd="$1"
		declare target_subcmd="$2"

		# Level 2/3: Help for specific subcommand OR direct command
		declare leaf_obj=""
		declare leaf_is_subcmd=false
		if [[ -n "$target_cmd" && -n "$target_subcmd" ]]; then
			leaf_obj="$(__cli_get_json ".commands[\"$target_cmd\"][\"$target_subcmd\"]")"
			leaf_is_subcmd=true
			if [[ -z "$leaf_obj" || "$leaf_obj" == "null" ]]; then
				__error "Unknown subcommand: $(__error_params "$target_cmd $target_subcmd")"
				return 1
			fi
		elif [[ -n "$target_cmd" ]]; then
			declare cmd_test_obj
			cmd_test_obj="$(__cli_get_json ".commands[\"$target_cmd\"]")"
			if [[ -z "$cmd_test_obj" || "$cmd_test_obj" == "null" ]]; then
				__error "Unknown command: $(__error_params "$target_cmd")"
				return 1
			fi
			declare has_action
			has_action="$(jq -r '.action // empty' <<<"$cmd_test_obj")"
			if [[ -n "$has_action" ]]; then
				leaf_obj="$cmd_test_obj"
			fi
		fi

		if [[ -n "$leaf_obj" && "$leaf_obj" != "null" ]]; then
			declare desc custom_usage
			desc="$(jq -r '.description // empty' <<<"$leaf_obj")"
			custom_usage="$(jq -r '.usage // empty' <<<"$leaf_obj")"

			__cli_show_version
			echo
			echo -e "$(__bold_underline "USAGE:")"
			if [[ -n "$custom_usage" ]]; then
				echo -e "$(__tab 1)$(eval echo "$custom_usage" 2>/dev/null || echo "$custom_usage")"
			elif $leaf_is_subcmd; then
				echo -e "$(__tab 1)$(__cli_generate_usage "$target_cmd" "$target_subcmd")"
			else
				echo -e "$(__tab 1)$(__cli_generate_usage "$target_cmd")"
			fi

			if [[ -n "$desc" ]]; then
				echo
				echo -e "$(__bold_underline "DESCRIPTION:")"
				echo -e "$(__tab 1)$desc"
			fi

			# Positional arguments
			declare args_json
			args_json="$(jq -c '.args // empty' <<<"$leaf_obj" 2>/dev/null)"
			if [[ "$args_json" != "empty" && "$args_json" != "null" && -n "$args_json" ]]; then
				echo
				echo -e "$(__bold_underline "ARGUMENTS:")"
				while IFS= read -r arg_item; do
					[[ -z "$arg_item" ]] && continue
					declare a_name a_type a_desc a_def a_opts
					a_name="$(jq -r '.name' <<<"$arg_item")"
					a_type="$(jq -r '.type // "String"' <<<"$arg_item")"
					a_desc="$(jq -r '.description // empty' <<<"$arg_item")"
					a_def="$(jq -r '.default // empty' <<<"$arg_item")"
					a_opts="$(jq -r '.options | if type=="array" then join(", ") else empty end' <<<"$arg_item" 2>/dev/null)"

					printf "%b  %b %b\n" "$(__tab 1)" "$(__yellow "<${a_name}>")" "$(__white "(${a_type})")"
					[[ -n "$a_desc" ]] && printf "%b    %s\n" "$(__tab 1)" "$a_desc"
					[[ -n "$a_opts" ]] && printf "%b    %b: %b\n" "$(__tab 1)" "$(__white "Options")" "$(__bright_blue "$a_opts")"
					[[ -n "$a_def" ]] && printf "%b    %b: %b\n" "$(__tab 1)" "$(__white "Default")" "$(__bright_green "$a_def")"
				done < <(jq -c '.[]' <<<"$args_json" 2>/dev/null)
			fi

			# Flags for leaf command
			declare flags_json
			flags_json="$(jq -c '.flags // empty' <<<"$leaf_obj" 2>/dev/null)"
			if [[ "$flags_json" != "empty" && "$flags_json" != "null" && -n "$flags_json" ]]; then
				echo
				echo -e "$(__bold_underline "FLAGS:")"
				while IFS= read -r flag_key; do
					[[ -z "$flag_key" ]] && continue
					declare f_obj f_desc f_aliases
					f_obj="$(jq -c ".flags[\"$flag_key\"]" <<<"$leaf_obj")"
					f_desc="$(jq -r '.description // empty' <<<"$f_obj")"
					f_aliases="$(jq -r '.aliases | if type=="array" then join(", ") else empty end' <<<"$f_obj" 2>/dev/null)"
					declare flag_label="--$flag_key"
					[[ -n "$f_aliases" ]] && flag_label="$f_aliases, --$flag_key"

					printf "%b  %-28b %s\n" "$(__tab 1)" "$(__bright_blue "$flag_label")" "$f_desc"
				done < <(jq -r '.flags | keys[]' <<<"$leaf_obj" 2>/dev/null)
			fi

			echo
			return 0
		fi

		# Level 2: Help for command group
		if [[ -n "$target_cmd" ]]; then
			declare cmd_obj
			cmd_obj="$(__cli_get_json ".commands[\"$target_cmd\"]")"
			if [[ -z "$cmd_obj" || "$cmd_obj" == "null" ]]; then
				__error "Unknown command: $(__error_params "$target_cmd")"
				return 1
			fi

			declare is_group
			is_group="$(__cli_get ".commands[\"$target_cmd\"] | type")"
			declare has_action
			has_action="$(__cli_get ".commands[\"$target_cmd\"].action")"

			if [[ "$is_group" == "object" && -z "$has_action" ]]; then
				__cli_show_version
				echo
				echo -e "$(__bold_underline "USAGE:")"
				echo -e "$(__tab 1)$(__cli_generate_usage "$target_cmd")"
				echo
				echo -e "$(__bold_underline "SUBCOMMANDS:")"

				while IFS= read -r sub_key; do
					[[ -z "$sub_key" ]] && continue
					declare s_obj s_desc s_aliases s_dev
					s_obj="$(jq -c ".[\"$sub_key\"]" <<<"$cmd_obj")"
					s_dev="$(jq -r '.dev // false' <<<"$s_obj")"
					if [[ "$s_dev" == "true" && "$opt_dev" != "true" ]]; then
						continue
					fi
					s_desc="$(jq -r '.description // empty' <<<"$s_obj")"
					s_aliases="$(jq -r '.aliases | if type=="array" then join(", ") else empty end' <<<"$s_obj" 2>/dev/null)"
					declare sub_label="$sub_key"
					[[ -n "$s_aliases" ]] && sub_label="$sub_key, $s_aliases"

					printf "%b  %-28b %s\n" "$(__tab 1)" "$(__bright_blue "$sub_label")" "$s_desc"
				done < <(jq -r 'keys[]' <<<"$cmd_obj" 2>/dev/null)

				echo
				echo -e "$(__white "Run '$(__purple "$__cli_name") $(__bright_blue "help $target_cmd <subcommand>")' for detailed options.")"
				echo
				return 0
			fi
		fi

		# Level 1: Root General Help
		__cli_show_version
		echo
		echo -e "$(__bold_underline "USAGE:")"
		if [[ -n "$__cli_usage_custom" ]]; then
			echo -e "$(__tab 1)$__cli_usage_custom"
		else
			echo -e "$(__tab 1)$(__cli_generate_usage)"
		fi

		echo
		echo -e "$(__bold_underline "GLOBAL FLAGS:")"
		printf "%b  %-28b %s\n" "$(__tab 1)" "$(__bright_blue "-h, --help")" "Show this help message"
		printf "%b  %-28b %s\n" "$(__tab 1)" "$(__bright_blue "-v, --version")" "Show the script version"
		while IFS= read -r gf_key; do
			[[ -z "$gf_key" ]] && continue
			declare gf_obj gf_desc gf_aliases
			gf_obj="$(__cli_get_json ".global_flags[\"$gf_key\"]")"
			gf_desc="$(jq -r '.description // empty' <<<"$gf_obj")"
			gf_aliases="$(jq -r '.aliases | if type=="array" then join(", ") else empty end' <<<"$gf_obj" 2>/dev/null)"
			declare gf_label="--$gf_key"
			[[ -n "$gf_aliases" ]] && gf_label="$gf_aliases, --$gf_key"

			printf "%b  %-28b %s\n" "$(__tab 1)" "$(__bright_blue "$gf_label")" "$gf_desc"
		done < <(__cli_get '.global_flags | keys[]' 2>/dev/null)

		echo
		echo -e "$(__bold_underline "COMMANDS:")"
		while IFS= read -r cmd_key; do
			[[ -z "$cmd_key" ]] && continue
			declare c_obj c_desc c_aliases c_dev c_is_group
			c_obj="$(__cli_get_json ".commands[\"$cmd_key\"]")"
			c_dev="$(jq -r '.dev // false' <<<"$c_obj")"
			if [[ "$c_dev" == "true" && "$opt_dev" != "true" ]]; then
				continue
			fi
			c_desc="$(jq -r '.description // empty' <<<"$c_obj")"
			c_aliases="$(jq -r '.aliases | if type=="array" then join(", ") else empty end' <<<"$c_obj" 2>/dev/null)"
			c_is_group="$(jq -r 'type' <<<"$c_obj")"
			declare c_has_action
			c_has_action="$(jq -r '.action // empty' <<<"$c_obj")"

			if [[ -z "$c_aliases" ]]; then
				case "$cmd_key" in
					install) c_aliases="i" ;;
					setup) c_aliases="s" ;;
				esac
			fi

			declare cmd_label="$cmd_key"
			[[ -n "$c_aliases" ]] && cmd_label="$cmd_key, $c_aliases"

			if [[ "$c_is_group" == "object" && -z "$c_has_action" ]]; then
				if [[ -z "$c_desc" ]]; then
					case "$cmd_key" in
						install) c_desc="Installation commands (arch, self, desktop-profile)" ;;
						setup) c_desc="System setup and customization commands" ;;
						*)
							declare sub_count
							sub_count="$(jq -r 'keys | length' <<<"$c_obj")"
							c_desc="Group with $sub_count subcommands"
							;;
					esac
				fi
			fi

			printf "%b  %-28b %s\n" "$(__tab 1)" "$(__bright_blue "$cmd_label")" "$c_desc"
		done < <(__cli_get '.commands | keys[]' 2>/dev/null)

		echo
		echo -e "$(__white "Run '$(__purple "$__cli_name") $(__bright_blue "help <command>")' for more information on a command.")"
		echo
		echo -e "Made with $(__bright_red "<3"), headache, coffee and $(__bright_green weed) by $(__red Sirius Red)\n"
	}

	# -- Flag and Argument Parsing ---------------------------------------------
	declare opt_dev=false opt_force=false opt_help=false opt_version=false
	declare -a raw_args=()

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--dev|-d)
				opt_dev=true
				shift 1
				;;
			--force|-f)
				opt_force=true
				export FORCE=true
				declare -gx __FORCE=true
				shift 1
				;;
			--config|-c)
				if [[ -z "$2" || "$2" == -* ]]; then
					__error "Argument required for $(__error_params "$1")"
					return 1
				fi
				declare custom_config="$2"
				shift 2
				if [[ -f "$custom_config" ]]; then
					__config_file="$(realpath "$custom_config" 2>/dev/null || readlink -f "$custom_config")"
					if __func_exists __reload_config; then
						__reload_config
					fi
				else
					__error "Configuration file not found: $(__error_params "$custom_config")"
					return 1
				fi
				;;
			--version|-v)
				opt_version=true
				shift 1
				;;
			--help|-h)
				opt_help=true
				shift 1
				;;
			*)
				raw_args+=("$1")
				shift 1
				;;
		esac
	done

	# Handle early --version
	if $opt_version; then
		__cli_show_version
		return 0
	fi

	# Handle early help or no args
	if [[ ${#raw_args[@]} -eq 0 ]]; then
		__cli_show_help
		return 0
	fi

	# -- Command / Subcommand Resolution helpers -------------------------------
	function __cli_resolve_cmd_name() {
		declare input="$1"
		if [[ -n "$(__cli_get ".commands[\"$input\"]")" ]]; then
			echo "$input"
			return 0
		fi
		declare resolved=""
		while IFS= read -r key; do
			[[ -z "$key" ]] && continue
			declare has_alias
			has_alias="$(__cli_get ".commands[\"$key\"].aliases // [] | index(\"$input\")")"
			if [[ "$has_alias" != "null" && -n "$has_alias" ]]; then
				resolved="$key"
				break
			fi
		done < <(__cli_get '.commands | keys[]' 2>/dev/null)

		if [[ -n "$resolved" ]]; then
			echo "$resolved"
			return 0
		fi

		case "$input" in
			i) echo "install" ;;
			s) echo "setup" ;;
			f) echo "func" ;;
			*) echo "$input" ;;
		esac
	}

	function __cli_resolve_subcmd_name() {
		declare parent_cmd="$1"
		declare input="$2"
		if [[ -n "$(__cli_get ".commands[\"$parent_cmd\"][\"$input\"]")" ]]; then
			echo "$input"
			return 0
		fi
		declare resolved=""
		while IFS= read -r subkey; do
			[[ -z "$subkey" ]] && continue
			declare has_alias
			has_alias="$(__cli_get ".commands[\"$parent_cmd\"][\"$subkey\"].aliases // [] | index(\"$input\")")"
			if [[ "$has_alias" != "null" && -n "$has_alias" ]]; then
				resolved="$subkey"
				break
			fi
		done < <(__cli_get ".commands[\"$parent_cmd\"] | keys[]" 2>/dev/null)

		echo "${resolved:-$input}"
	}

	# Handle "help" command keyword
	if [[ "${raw_args[0]}" =~ ^help$|^h$ ]]; then
		declare help_cmd="${raw_args[1]}"
		declare help_subcmd="${raw_args[2]}"

		if [[ -n "$help_cmd" ]]; then
			help_cmd="$(__cli_resolve_cmd_name "$help_cmd")"
			if [[ -n "$help_subcmd" ]]; then
				help_subcmd="$(__cli_resolve_subcmd_name "$help_cmd" "$help_subcmd")"
			fi
		fi

		__cli_show_help "$help_cmd" "$help_subcmd"
		return 0
	fi

	# If --help flag was passed alongside a command
	if $opt_help; then
		declare help_cmd="${raw_args[0]}"
		declare help_subcmd="${raw_args[1]}"
		help_cmd="$(__cli_resolve_cmd_name "$help_cmd")"
		if [[ -n "$help_subcmd" ]]; then
			help_subcmd="$(__cli_resolve_subcmd_name "$help_cmd" "$help_subcmd")"
		fi
		__cli_show_help "$help_cmd" "$help_subcmd"
		return 0
	fi

	declare parsed_cmd="${raw_args[0]}"
	declare resolved_cmd
	resolved_cmd="$(__cli_resolve_cmd_name "$parsed_cmd")"

	declare cmd_target_obj
	cmd_target_obj="$(__cli_get_json ".commands[\"$resolved_cmd\"]")"
	if [[ -z "$cmd_target_obj" || "$cmd_target_obj" == "null" ]]; then
		__error "Unknown command: $(__error_params "$parsed_cmd")"
		echo
		__cli_show_help
		return 1
	fi

	declare is_group
	is_group="$(__cli_get ".commands[\"$resolved_cmd\"] | type")"
	declare has_direct_action
	has_direct_action="$(__cli_get ".commands[\"$resolved_cmd\"].action")"

	declare target_action=""
	declare -a target_args_schema=()
	declare target_is_dev=false
	declare target_is_root=false
	declare target_is_reboot=false
	declare -a remaining_cli_args=()
	declare target_full_name=""

	if [[ "$is_group" == "object" && -z "$has_direct_action" ]]; then
		if [[ ${#raw_args[@]} -lt 2 ]]; then
			__cli_show_help "$resolved_cmd"
			return 0
		fi

		declare parsed_subcmd="${raw_args[1]}"
		declare resolved_subcmd
		resolved_subcmd="$(__cli_resolve_subcmd_name "$resolved_cmd" "$parsed_subcmd")"

		declare subcmd_target_obj
		subcmd_target_obj="$(__cli_get_json ".commands[\"$resolved_cmd\"][\"$resolved_subcmd\"]")"
		if [[ -z "$subcmd_target_obj" || "$subcmd_target_obj" == "null" ]]; then
			__error "Unknown subcommand: $(__error_params "$parsed_cmd $parsed_subcmd")"
			echo
			__cli_show_help "$resolved_cmd"
			return 1
		fi

		target_full_name="$resolved_cmd $resolved_subcmd"
		target_action="$(jq -r '.action // empty' <<<"$subcmd_target_obj")"
		target_is_dev="$(jq -r '.dev // false' <<<"$subcmd_target_obj")"
		target_is_root="$(jq -r '.root_required // false' <<<"$subcmd_target_obj")"
		target_is_reboot="$(jq -r '.reboot // false' <<<"$subcmd_target_obj")"
		mapfile -t target_args_schema < <(jq -c '.args[]? // empty' <<<"$subcmd_target_obj" 2>/dev/null)
		remaining_cli_args=("${raw_args[@]:2}")
	else
		target_full_name="$resolved_cmd"
		target_action="$(jq -r '.action // empty' <<<"$cmd_target_obj")"
		target_is_dev="$(jq -r '.dev // false' <<<"$cmd_target_obj")"
		target_is_root="$(jq -r '.root_required // false' <<<"$cmd_target_obj")"
		target_is_reboot="$(jq -r '.reboot // false' <<<"$cmd_target_obj")"
		mapfile -t target_args_schema < <(jq -c '.args[]? // empty' <<<"$cmd_target_obj" 2>/dev/null)
		remaining_cli_args=("${raw_args[@]:1}")
	fi

	# Dev check
	if [[ "$target_is_dev" == "true" && "$opt_dev" != "true" ]]; then
		__error "The command \`$(__error_params "$target_full_name")\` is only available in development mode"
		__info "Runs \`$(__info_params "archzen --dev $target_full_name")\`"
		return 1
	fi

	# Root privilege check based on schema
	if [[ "$target_is_root" == "true" && $EUID -ne 0 ]]; then
		__error "The command \`$(__error_params "$target_full_name")\` must be run as root"
		return 1
	fi

	# Validate positional arguments
	declare -a validated_args=()
	declare -i schema_idx=0
	declare -i schema_count=${#target_args_schema[@]}

	for ((schema_idx = 0; schema_idx < schema_count; schema_idx++)); do
		declare arg_def="${target_args_schema[$schema_idx]}"
		[[ -z "$arg_def" ]] && continue

		declare a_name a_req a_def a_var
		a_name="$(jq -r '.name' <<<"$arg_def")"
		a_req="$(jq -r '.required // true' <<<"$arg_def")"
		a_def="$(jq -r '.default // empty' <<<"$arg_def")"
		a_var="$(jq -r '.variadic // false' <<<"$arg_def")"

		declare user_val="${remaining_cli_args[$schema_idx]}"

		if [[ "$a_var" == "true" ]]; then
			declare -a rest_vals=("${remaining_cli_args[@]:$schema_idx}")
			if [[ ${#rest_vals[@]} -eq 0 && "$a_req" == "true" ]]; then
				__error "Missing required argument for $(__error_params "\`$target_full_name\`"): $(__error_params "<$a_name>")"
				return 1
			fi
			validated_args+=("${rest_vals[@]}")
			break
		fi

		if [[ -z "$user_val" ]]; then
			if [[ "$a_req" == "true" ]]; then
				__error "Missing required argument for $(__error_params "\`$target_full_name\`"): $(__error_params "<$a_name>")"
				return 1
			elif [[ -n "$a_def" ]]; then
				user_val="$a_def"
			fi
		fi

		if [[ -n "$user_val" ]]; then
			declare has_opts
			has_opts="$(jq -r '.options | if type=="array" then "true" else "false" end' <<<"$arg_def" 2>/dev/null)"
			if [[ "$has_opts" == "true" ]]; then
				declare is_valid_opt
				is_valid_opt="$(jq -r --arg val "$user_val" '.options | index($val) // empty' <<<"$arg_def" 2>/dev/null)"
				if [[ -z "$is_valid_opt" ]]; then
					declare allowed_opts
					allowed_opts="$(jq -r '.options | join(" | ")' <<<"$arg_def" 2>/dev/null)"
					__error "Invalid value for $(__error_params "<$a_name>"): $(__error_params "$user_val")"
					__info "Allowed choices: $(__info_params "$allowed_opts")"
					return 1
				fi
			fi

			validated_args+=("$user_val")
		fi
	done

	if [[ -z "$target_action" ]]; then
		__error "No action defined for command: $(__error_params "$target_full_name")"
		return 1
	fi

	if ! __func_exists "$target_action"; then
		__error "Target action function not found: $(__error_params "$target_action")"
		return 1
	fi

	# Execution Dispatch
	__COMMAND_ARG="$target_full_name"
	[[ "$target_is_reboot" == "true" ]] && __REBOOT_SYSTEM=true

	# Prepare call arguments including --force if set
	declare -a action_call_args=("${validated_args[@]}")
	if $opt_force; then
		action_call_args+=("--force")
		export FORCE=true
		declare -gx __FORCE=true
	fi

	__init || return $?
	"$target_action" "${action_call_args[@]}"
	declare -i action_status=$?
	__finish
	return $action_status
}

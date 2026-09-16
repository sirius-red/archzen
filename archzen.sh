#!/usr/bin/env bash


declare __script_dir __cli_config_file
__script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
__cli_config_file="${__script_dir}/source/cli/config.yml"


# >>>>>>>>>>>>>>>>>>>>>>>> Load Source Files >>>>>>>>>>>>>>>>>>>>>>>>
declare __source_dir=""
__source_dir="${__script_dir}/source"

# shellcheck source=source/lib/confmgr.sh
source "${__source_dir}/lib/confmgr.sh"

# shellcheck source=source/lib/cli_parser.sh
source "${__source_dir}/lib/cli_parser.sh"

# shellcheck source=source/core/user_settings.sh
source "${__source_dir}/core/user_settings.sh"

# shellcheck source=source/global_declarations.sh
source "${__source_dir}/global_declarations.sh"

# shellcheck source=source/utils/string.sh
source "${__source_dir}/utils/string.sh"
# shellcheck source=source/utils/array.sh
source "${__source_dir}/utils/array.sh"

# shellcheck source=source/core/validations.sh
source "${__source_dir}/core/validations.sh"
# shellcheck source=source/core/ui_components.sh
source "${__source_dir}/core/ui_components.sh"
# shellcheck source=source/core/package_management.sh
source "${__source_dir}/core/package_management.sh"
# shellcheck source=source/core/internal_setup_steps.sh
source "${__source_dir}/core/internal_setup_steps.sh"

# shellcheck source=source/cli/actions.sh
source "${__source_dir}/cli/actions.sh"
# shellcheck source=source/cli/lifecycle_functions.sh
source "${__source_dir}/cli/lifecycle_functions.sh"

unset __source_dir
# <<<<<<<<<<<<<<<<<<<<<<<< Load Source Files <<<<<<<<<<<<<<<<<<<<<<<<


__set_global_variables "${CHDIR:-/}" "${__ARCHZEN_FLAG_FORCE:-false}" "${ARCHZEN_IS_RUNNING_FROM_BINARY:-false}"


if [[ "$ARCHZEN_PROCESS_ENV" == development ]]; then
	cli_parser --pre-action-hook __init "$__cli_config_file" "$@"
	__finish
	exit $?
fi

if __is_main_module; then
	__ensure_deps --quiet

	# shellcheck disable=SC2329
	function __archzen_pre_action_hook() {
		declare target_cmd="$1"
		shift 1

		if [[ "$target_cmd" =~ ^install ]]; then
			return 0
		fi

		if ! command -v archzen &>>"$__LOG_FILE"; then
			echo
			__error "The \`$(__error_params "$target_cmd")\` command is only available after the installation of ArchZen"
			__info "Run \`$(__info_params "sudo ${__THIS_SCRIPT} install self")\` first"
			echo
			return 1
		fi

		if ! $__ARCHZEN_IS_RUNNING_FROM_BINARY; then
			echo
			__error "Do not run the command \`$(__error_params "$target_cmd")\` through this script"
			declare cmd_suggestion="archzen ${target_cmd}"
			[[ $# -gt 0 ]] && cmd_suggestion+=" $*"
			__info "Run \`$(__info_params "$cmd_suggestion")\`"
			echo
			return 1
		fi

		__init

		return $?
	}

	cli_parser --pre-action-hook __archzen_pre_action_hook "$__cli_config_file" "$@" || __EXIT_CODE=$?
	__finish
	exit $__EXIT_CODE
fi
